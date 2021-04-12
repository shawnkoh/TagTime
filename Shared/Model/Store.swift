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

    let pingService: PingService
    let notificationService = NotificationService()

    let settings: Settings
    let user: User
    let userDocument: DocumentReference
    let answerCollection: CollectionReference

    var alertService = AlertService()

    private var subscribers = Set<AnyCancellable>()
    private var listeners = [ListenerRegistration]()

    init(settings: Settings, user: User) {
        self.settings = settings
        self.user = user
        self.pingService = .init(startDate: user.startDate)
        self.userDocument = Firestore.firestore().collection("users").document(user.id)
        self.answerCollection = userDocument.collection("answers")
        
        setup()
        setupSubscribers()

        getUnansweredPings() {
            self.pings = $0
        }
    }

    private func setup() {
        answerCollection
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
            .store(in: &listeners)

        notificationService.requestAuthorization() { (granted, error) in
            if let error = error {
                self.alertService.present(message: "error while requesting authorisation \(error.localizedDescription)")
            }

            guard granted else {
                self.alertService.present(message: "Unable to schedule notifications, not granted permission")
                return
            }

            self.setupNotificationObserver()
        }
    }

    private func setupNotificationObserver() {
        answerCollection
            .order(by: "ping", descending: true)
            .limit(to: 1)
            .addSnapshotListener() { (snapshot, error) in
                guard let snapshot = snapshot else {
                    self.alertService.present(message: "Failed to update notifications. answerCollection snapshot = nil")
                    return
                }
                do {
                    // TODO: Arbitrarily selected number. Maximum notifications = 64? not sure yet.
                    let pings = self.pingService
                        .nextPings(count: 30)
                        .map { $0.date }

                    if let answer = try snapshot.documents.first?.data(as: Answer.self) {
                        self.notificationService.tryToScheduleNotifications(pings: pings, previousAnswer: answer)
                    } else {
                        self.notificationService.tryToScheduleNotifications(pings: pings, previousAnswer: nil)
                    }
                } catch {
                    self.alertService.present(message: error.localizedDescription)
                }
            }
            .store(in: &listeners)
    }

    private func setupSubscribers() {
        // TODO: This should recompute pings
        settings.$averagePingInterval
            .sink { self.pingService.averagePingInterval = $0 * 60 }
            .store(in: &subscribers )
    }

    func addAnswer(_ answer: Answer) {
        do {
            try answerCollection
                .document(answer.ping.documentId)
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
        answerCollection
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
                    let answerablePings = self.pingService.answerablePings()
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

    func updateAnswer(_ answer: Answer) {
        do {
            try answerCollection
                .document(answer.ping.documentId)
                .setData(from: answer)
        } catch {
            alertService.present(message: "updateAnswer(_:) \(error)")
        }
    }
}
