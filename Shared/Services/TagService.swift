//
//  TagService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 28/4/21.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseFirestoreSwift
import Resolver

final class TagService: ObservableObject {
    @Published var tags: [Tag: TagCache] = [:]
    private(set) lazy var activeTagsPublisher = $tags
        .flatMap {
            $0.publisher
                .filter { $0.value.count > 0 }
                .map { $0.key }
                .collect()
        }

    private var userSubscriber: AnyCancellable = .init({})
    
    private var subscribers = Set<AnyCancellable>()
    private var listeners = [ListenerRegistration]()

    @Injected private var alertService: AlertService
    @Injected private var authenticationService: AuthenticationService

    private var user: User {
        authenticationService.user
    }

    private var cache: CollectionReference {
        user.userDocument.collection("tags")
    }
    
    init() {
        userSubscriber = authenticationService.$user
            .sink { self.setup(user: $0) }
    }
    
    private func setup(user: User?) {
        subscribers.forEach { $0.cancel() }
        subscribers = []
        listeners.forEach { $0.remove() }
        listeners = []
        guard let user = user else {
            return
        }
        user.userDocument.collection("tags")
            .addSnapshotListener() { snapshot, error in
                if let error = error {
                    self.alertService.present(message: error.localizedDescription)
                }
                guard let snapshot = snapshot else {
                    return
                }
                snapshot.documents.forEach {
                    do {
                        guard let tagCache = try $0.data(as: TagCache.self) else {
                            return
                        }
                        self.tags[$0.documentID] = tagCache
                    } catch {
                        self.alertService.present(message: error.localizedDescription)
                    }
                }
            }
            .store(in: &listeners)
    }

    // TODO: Chunk this to avoid firestore limit of 500 writes. Very small probability but defensive coding.
    func registerTags(_ tags: [Tag], with batch: WriteBatch? = nil, increment: Int = 1) {
        let willCommit = batch == nil
        let batch = batch ?? Firestore.firestore().batch()
        
        tags.forEach { tag in
            let documentReference = cache.document(tag)
            let tagCache: TagCache
            if let localTagCache = self.tags[tag] {
                tagCache = TagCache(count: localTagCache.count + increment, updatedDate: Date())
            } else {
                tagCache = TagCache(count: increment, updatedDate: Date())
            }
            try! batch.setData(from: tagCache, forDocument: documentReference)
        }

        guard willCommit else {
            return
        }

        batch.commit() { error in
            if let error = error {
                self.alertService.present(message: error.localizedDescription)
            }
        }
    }
    
    // TODO: Chunk this to avoid firestore limit of 500 writes. Very small probability but defensive coding.
    func deregisterTags(_ tags: [Tag], with batch: WriteBatch? = nil, decrement: Int = -1) {
        let willCommit = batch == nil
        let batch = batch ?? Firestore.firestore().batch()

        // you can't deregister tags like this
        // because we need to check how many are pointing to it in firestore, not just locally
        // the problem is, that requires multiple reads to retrieve those a tag that contains
        // okay so the solution is to maintain a count of the tags
        // that data can be useful for recommending also i guess
        let tagsToRemove = tags.filter { cacheContains(tag: $0) }
        guard tagsToRemove.count > 0 else {
            return
        }
        
        tagsToRemove.forEach { tag in
            let documentReference = cache.document(tag)
            guard let localTagCache = self.tags[tag], localTagCache.count > 0 else {
                return
            }
            let count = min(0, localTagCache.count + decrement)
            let tagCache = TagCache(count: count, updatedDate: Date())
            try! batch.setData(from: tagCache, forDocument: documentReference)
        }

        guard willCommit else {
            return
        }
        
        batch.commit() { error in
            if let error = error {
                self.alertService.present(message: error.localizedDescription)
            }
        }
    }
    
    private func cacheContains(tag: Tag) -> Bool {
        guard let tagCache = tags[tag] else {
            return false
        }
        return tagCache.count > 0
    }
}

#if DEBUG
extension TagService {
    func resetTagCache() {
        cache.getDocuments() { snapshot, error in
            if let error = error {
                self.alertService.present(message: error.localizedDescription)
            }
            guard let snapshot = snapshot else {
                return
            }
            let batch = Firestore.firestore().batch()
            snapshot.documents.forEach { batch.deleteDocument($0.reference) }
            batch.commit() { error in
                if let error = error {
                    self.alertService.present(message: error.localizedDescription)
                }
            }
        }
    }
}
#endif
