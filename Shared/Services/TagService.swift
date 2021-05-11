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

final class TagService {
    @Injected private var alertService: AlertService
    @Injected private var authenticationService: AuthenticationService

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

    private var serverListener: ListenerRegistration?

    @Published private var lastFetched: LastFetchedStatus = .loading

    private var user: User {
        authenticationService.user
    }

    private var tagCollection: CollectionReference {
        user.userDocument.collection("tags")
    }
    
    init() {
        userSubscriber = authenticationService.userPublisher
            .sink { self.setup(user: $0) }
    }
    
    private func setup(user: User) {
        subscribers.forEach { $0.cancel() }
        subscribers = []
        listeners.forEach { $0.remove() }
        listeners = []
        tags = [:]
        lastFetched = .loading
        serverListener?.remove()
        serverListener = nil
        guard user.isAuthenticated else {
            return
        }
        // Using self.tagCollection results in referring to unauthenticated
        // The publisher fires first before the property was updated
        let tagCollection = user.userDocument.collection("tags")

        tagCollection
            .order(by: "updatedDate", descending: true)
            .limit(to: 1)
            .getDocuments(source: .cache)
            .map { snapshot in
                try? snapshot.documents.first?.data(as: TagCache.self)?.updatedDate
            }
            .replaceNil(with: user.startDate)
            .replaceError(with: user.startDate)
            .sink { lastFetched in
                self.lastFetched = .lastFetched(lastFetched)
            }
            .store(in: &subscribers)

        tagCollection
            .getDocuments(source: .cache)
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    self.alertService.present(message: error.localizedDescription)
                case .finished:
                    ()
                }
            }, receiveValue: { snapshot in
                snapshot.documents.forEach {
                    self.tags[$0.documentID] = try? $0.data(as: TagCache.self)
                }
            })
            .store(in: &subscribers)

        $lastFetched
            // Prevents infinite recursion
            .removeDuplicates()
            .sink { lastFetched in
                self.serverListener?.remove()
                self.serverListener = nil
                guard case let .lastFetched(lastFetched) = lastFetched else {
                    return
                }

                self.serverListener = tagCollection
                    .whereField("updatedDate", isGreaterThan: lastFetched)
                    .addSnapshotListener { snapshot, error in
                        if let error = error {
                            self.alertService.present(message: error.localizedDescription)
                        }

                        guard let snapshot = snapshot else {
                            return
                        }

                        let result = snapshot.documents.compactMap { document -> (String, TagCache)? in
                            guard let tagCache = try? document.data(as: TagCache.self) else {
                                return nil
                            }
                            return (document.documentID, tagCache)
                        }

                        result.forEach { tag, tagCache in
                            self.tags[tag] = tagCache
                        }

                        if let lastFetched = result.map({ $0.1.updatedDate }).max() {
                            self.lastFetched = .lastFetched(lastFetched)
                        }
                    }
            }
            .store(in: &subscribers)
    }

    // TODO: Chunk this to avoid firestore limit of 500 writes. Very small probability but defensive coding.
    func registerTags(_ tags: [Tag], with batch: WriteBatch? = nil, increment: Int = 1) {
        let willCommit = batch == nil
        let batch = batch ?? Firestore.firestore().batch()
        
        tags.forEach { tag in
            let documentReference = tagCollection.document(tag)
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
            let documentReference = tagCollection.document(tag)
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
        tagCollection.getDocuments(source: .cache) { snapshot, error in
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

        tagCollection.getDocuments() { snapshot, error in
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
