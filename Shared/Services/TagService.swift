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

final class TagService: ObservableObject {
    static let shared = TagService()
    
    @Published var tags: [Tag: TagCache] = [:]
    private var userSubscriber: AnyCancellable = .init({})
    
    private var subscribers = Set<AnyCancellable>()
    private var listeners = [ListenerRegistration]()
    
    init() {
        userSubscriber = AuthenticationService.shared.$user
            .sink { self.setup(user: $0) }
    }
    
    var cache: CollectionReference? {
        AuthenticationService.shared.user?.userDocument.collection("tags")
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
                    AlertService.shared.present(message: error.localizedDescription)
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
                        AlertService.shared.present(message: error.localizedDescription)
                    }
                }
            }
            .store(in: &listeners)
    }

    // TODO: Chunk this to avoid firestore limit of 500 writes. Very small probability but defensive coding.
    func batchTags(register: [Tag], deregister: [Tag], with batch: WriteBatch = Firestore.firestore().batch()) {
        registerTags(register, with: batch)
        deregisterTags(deregister, with: batch)
    }

    // TODO: Chunk this to avoid firestore limit of 500 writes. Very small probability but defensive coding.
    func registerTags(_ tags: [Tag], with batch: WriteBatch = Firestore.firestore().batch()) {
        guard let cacheReference = cache else {
            return
        }
        
        tags.forEach { tag in
            let documentReference = cacheReference.document(tag)
            let tagCache: TagCache
            if let localTagCache = self.tags[tag] {
                tagCache = TagCache(count: localTagCache.count + 1, updatedDate: Date())
            } else {
                tagCache = TagCache(count: 1, updatedDate: Date())
            }
            try! batch.setData(from: tagCache, forDocument: documentReference)
        }
        
        batch.commit() { error in
            if let error = error {
                AlertService.shared.present(message: error.localizedDescription)
            }
        }
    }
    
    // TODO: Chunk this to avoid firestore limit of 500 writes. Very small probability but defensive coding.
    func deregisterTags(_ tags: [Tag], with batch: WriteBatch = Firestore.firestore().batch()) {
        guard let cacheReference = cache else {
            return
        }
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
            let documentReference = cacheReference.document(tag)
            guard let localTagCache = self.tags[tag], localTagCache.count > 0 else {
                return
            }
            let tagCache = TagCache(count: localTagCache.count - 1, updatedDate: Date())
            try! batch.setData(from: tagCache, forDocument: documentReference)
        }
        
        batch.commit() { error in
            if let error = error {
                AlertService.shared.present(message: error.localizedDescription)
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