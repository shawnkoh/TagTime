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
    @Published private(set) var tags: [Tag] = Stub.tags
    // Solely updated by Firestore listener
    @Published private(set) var answers: [Answer] = []
    // Solely updated by publisher
    @Published private(set) var unansweredPings: [Ping] = []

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
    }

    private func setup() {
        // TODO: We should not be observing the entire answer collection
        // Rather, we should only observe a paginated version for displaying Logbook.
        // But take note that if you change this, you also need to implement a snapshot listener for maintaining unansweredPings
        // The most ideal solution would be to have a dedicated snapshot listener for every use case, but for now, this will do.
        // It's a quick hack but at the cost of incurring many Firestore reads
        answerCollection
            .addSnapshotListener() { (snapshot, error) in
                guard let snapshot = snapshot else {
                    // TODO: Log error
                    return
                }
                do {
                    self.answers = try snapshot.documents.compactMap { try $0.data(as: Answer.self) }
                    print("updated answers", self.answers)
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

        // Update unansweredPings by comparing answerablePings with answers.
        // answerablePings is maintained by PingService
        // answers is maintained by observing Firestore's answers
        // TODO: We need to find a way to minimise the number of reads for this.
        pingService.$answerablePings
            .combineLatest($answers)
            .map { (answerablePings, answers) -> [Ping] in
                let answeredPings = Set(answers.map { $0.ping })

                let unansweredPings = answerablePings
                    .filter { !answeredPings.contains($0.date) }
                    .map { $0.date }

                return unansweredPings
            }
            .sink { self.unansweredPings = $0 }
            .store(in: &subscribers)
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
                    let answerablePings = self.pingService.answerablePings
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

    func answerAllUnansweredPings(tags: [Tag]) {
        unansweredPings
            .map { Answer(ping: $0, tags: tags) }
            .forEach { addAnswer($0) }
    }
}
