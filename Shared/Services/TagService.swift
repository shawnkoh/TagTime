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
    
    @Published var tags: [Tag: Tag] = [:]
    private var userSubscriber: AnyCancellable = .init({})
    
    private var subscribers = Set<AnyCancellable>()
    private var listeners = [ListenerRegistration]()
    
    init() {
        userSubscriber = AuthenticationService.shared.$user
            .sink { self.setup(user: $0) }
    }
    
    var cache: DocumentReference? {
        AuthenticationService.shared.user?.userDocument.collection("cache").document("tags")
    }
    
    private func setup(user: User?) {
        subscribers.forEach { $0.cancel() }
        subscribers = []
        listeners.forEach { $0.remove() }
        listeners = []
        guard let user = user else {
            return
        }
        user.userDocument.collection("cache").document("tags")
            .addSnapshotListener() { snapshot, error in
                if let error = error {
                    AlertService.shared.present(message: error.localizedDescription)
                }
                guard let snapshot = snapshot else {
                    return
                }
                do {
                    if let userTags = try snapshot.data(as: UserTags.self) {
                        self.tags = userTags.tags
                    } else {
                        self.tags = [:]
                    }
                } catch {
                    AlertService.shared.present(message: error.localizedDescription)
                }
            }
            .store(in: &listeners)
    }
    
    func registerTags(_ tags: [Tag]) {
        guard let cacheReference = cache else {
            return
        }
        let newTags = tags.filter { !cacheContains(tag: $0) }
        guard newTags.count > 0 else {
            return
        }
        
        var tags = self.tags
        newTags.forEach { tags[$0] = $0 }
        let userTags = UserTags(tags: tags)
        
        do {
            try cacheReference.setData(from: userTags)
        } catch {
            AlertService.shared.present(message: error.localizedDescription)
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
        
        var tags = self.tags
        tagsToRemove.forEach { tags[$0] = nil }
        let userTags = UserTags(tags: tags)
        
        do {
            try cacheReference.setData(from: userTags)
        } catch {
            AlertService.shared.present(message: error.localizedDescription)
        }
    }
    
    private func cacheContains(tag: Tag) -> Bool {
        tags[tag] != nil
    }
}
