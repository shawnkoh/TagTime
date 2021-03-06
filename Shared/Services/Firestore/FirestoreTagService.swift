//
//  FirestoreTagService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 12/5/21.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseFirestoreSwift
import Resolver

final class FirestoreTagService: TagService {
    @LazyInjected private var alertService: AlertService
    @LazyInjected private var authenticationService: AuthenticationService

    @Published var tags: [Tag: TagCache] = [:]
    var tagsPublisher: Published<[Tag : TagCache]>.Publisher { $tags }

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
            .removeDuplicatesForServices()
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
            // remote fetch before activating snapshot listener
            // because snapshot listener seems to not guarantee that the data is sent as a batch
            .flatMap { lastFetched -> AnyPublisher<Date, Error> in
                tagCollection
                    .whereField("updatedDate", isGreaterThan: lastFetched)
                    .order(by: "updatedDate")
                    .getDocuments(source: .default)
                    .flatMap { snapshot -> AnyPublisher<Date, Error> in
                        let result = snapshot.documents.compactMap { document -> (String, TagCache)? in
                            guard let tagCache = try? document.data(as: TagCache.self) else {
                                return nil
                            }
                            return (document.documentID, tagCache)
                        }
                        var tags = self.tags
                        result.forEach { documentId, tagCache in
                            tags[documentId] = tagCache
                        }
                        self.tags = tags

                        if let lastFetched = result.map({ $0.1.updatedDate }).max() {
                            return Just(lastFetched).setFailureType(to: Error.self).eraseToAnyPublisher()
                        } else {
                            return Just(lastFetched).setFailureType(to: Error.self).eraseToAnyPublisher()
                        }
                    }
                    .eraseToAnyPublisher()
            }
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
                var tags = self.tags
                snapshot.documents.forEach {
                    tags[$0.documentID] = try? $0.data(as: TagCache.self)
                }
                self.tags = tags
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
                    // Firestore is like a hash table. If the query is not sorted, there's no guarantee it will
                    // retrieve the further updated date first.
                    .order(by: "updatedDate")
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

                        var tags = self.tags
                        result.forEach { tag, tagCache in
                            tags[tag] = tagCache
                        }
                        self.tags = tags

                        if let lastFetched = result.map({ $0.1.updatedDate }).max() {
                            self.lastFetched = .lastFetched(lastFetched)
                        }
                    }
            }
            .store(in: &subscribers)
    }

    func registerTag(tag: Tag, batch: WriteBatch, delta: Int) {
        let count: Int
        if let localTagCache = self.tags[tag] {
            count = max(0, localTagCache.count + delta)
        } else {
            count = max(0, delta)
        }
        let tagCache = TagCache(count: count, updatedDate: Date())
        try! batch.setData(from: tagCache, forDocument: tagCollection.document(tag))
    }
}

#if DEBUG
extension FirestoreTagService {
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
