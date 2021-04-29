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
    
    @Published var tags: [Tag: Int] = [:]
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
                    guard let count = $0.data()["count"] as? Int else {
                        return
                    }
                    self.tags[$0.documentID] = count
                }
            }
            .store(in: &listeners)
    }
    
    func registerTags(_ tags: [Tag]) {
        guard let cacheReference = cache else {
            return
        }
        
        // TODO: Chunk this to avoid firestore limit of 500 writes. Very small probability but defensive coding.
        let batch = Firestore.firestore().batch()
        tags.forEach { tag in
            let documentReference = cacheReference.document(tag)
            if let count = self.tags[tag] {
                batch.setData(["count": count + 1], forDocument: documentReference)
            } else {
                batch.setData(["count": 1], forDocument: documentReference)
            }
        }
        
        batch.commit() { error in
            if let error = error {
                AlertService.shared.present(message: error.localizedDescription)
            }
        }
    }
    
    func deregisterTags(_ tags: [Tag]) {
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
        
        // TODO: Chunk this to avoid firestore limit of 500 writes. Very small probability but defensive coding.
        let batch = Firestore.firestore().batch()
        tagsToRemove.forEach { tag in
            let documentReference = cacheReference.document(tag)
            guard let count = self.tags[tag], count > 0 else {
                return
            }
            batch.setData(["count": count - 1], forDocument: documentReference)
        }
        
        batch.commit() { error in
            if let error = error {
                AlertService.shared.present(message: error.localizedDescription)
            }
        }
    }
    
    private func cacheContains(tag: Tag) -> Bool {
        guard let count = tags[tag] else {
            return false
        }
        return count > 0
    }
}
