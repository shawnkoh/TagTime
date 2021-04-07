//
//  Store.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/4/21.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

final class Store: ObservableObject {
    @Published var pings: [Ping] = Stub.pings
    @Published var tags: [Tag] = Stub.tags
    @Published var answers: [Answer] = []

    let user: User

    init(user: User) {
        self.user = user
        setup()
    }

    private var listener: ListenerRegistration?

    private func setup() {
        self.listener = Firestore.firestore()
            .collection("users")
            .document(user.id)
            .collection("answers")
            .addSnapshotListener() { (snapshot, error) in
                guard let snapshot = snapshot else {
                    // TODO: Log error
                    return
                }
                // TODO: find a better way to handle situations like these
                do {
                    self.answers = try snapshot.documents.compactMap { try $0.data(as: Answer.self) }
                } catch {
                    // TODO: Log error
                }
            }
    }
}
