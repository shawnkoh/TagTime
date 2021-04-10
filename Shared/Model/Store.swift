//
//  Store.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/4/21.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift
import Combine

final class Store: ObservableObject {
    @Published var pings: [Ping] = []
    @Published var tags: [Tag] = Stub.tags
    @Published var answers: [Answer] = []

    let pingService = PingService()

    let settings: Settings
    let user: User

    var subscribers = Set<AnyCancellable>()

    init(settings: Settings, user: User) {
        self.settings = settings
        self.user = user
        setup()
        setupSubscribers()

        getUnansweredPings() {
            self.pings = $0
        }
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

    private func setupSubscribers() {
        // TODO: This should recompute pings
        settings.$averagePingInterval
            .sink { self.pingService.averagePingInterval = $0 * 60 }
            .store(in: &subscribers )
    }

    func addAnswer(_ answer: Answer) {
        do {
            try Firestore.firestore()
                .collection("users")
                .document(user.id)
                .collection("answers")
                .document(answer.ping.timeIntervalSince1970.description)
                .setData(from: answer) { error in
                    guard let error = error else {
                        return
                    }
                    // TODO: Log error
                    print("unable to save answer", error)
                }
        } catch {
            // TODO: Log error
            print("Unable to add answer")
        }
    }

    func getUnansweredPings(completion: @escaping (([Ping]) -> Void)) {
        let now = Date()
        Firestore.firestore()
            .collection("users")
            .document(user.id)
            .collection("answers")
            .order(by: "ping", descending: true)
            .whereField("ping", isGreaterThanOrEqualTo: user.startDate)
            // TODO: We should probably filter this even more to not incur so many reads.
            .whereField("ping", isLessThanOrEqualTo: now)
            .getDocuments() { (snapshot, error) in
                guard let snapshot = snapshot else {
                    print("returned")
                    // TODO: Log this
                    return
                }
                do {
                    let answerablePings = self.pingService.answerablePings(startDate: self.user.startDate)
                        .map { $0.date }
                    var answerablePingSet = Set(answerablePings)
                    try snapshot.documents
                        .compactMap { try $0.data(as: Answer.self) }
                        .map { $0.ping }
                        .forEach { answerablePingSet.remove($0) }
                    let result = answerablePingSet.sorted()
                    completion(result)
                } catch {
                    // TODO: Log this
                    print("error", error)
                }
            }
    }
}
