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
    @Published private(set) var unansweredPings: [Date] = []
    // Solely updated by Firestore listener
    @Published private(set) var latestAnswer: Answer?

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

        notificationService.delegate = self

        setup()
    }

    private func setup() {
        setupFirestoreListeners()
        setupSubscribers()

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

    private func setupFirestoreListeners() {
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
                } catch {
                    // TODO: Log error
                }
            }
            .store(in: &listeners)

        answerCollection
            .order(by: "ping", descending: true)
            .limit(to: 1)
            .addSnapshotListener() { [self] (snapshot, error) in
                if let error = error {
                    alertService.present(message: "setupFirestoreListeners \(error.localizedDescription)")
                }

                guard let snapshot = snapshot else {
                    alertService.present(message: "setupFirestoreListeners unable to get snapshot")
                    return
                }

                do {
                    latestAnswer = try snapshot.documents.first?.data(as: Answer.self)
                } catch {
                    alertService.present(message: "setupFirestoreListeners unable to decode latestAnswer")
                }
            }
            .store(in: &listeners)
    }

    private func setupNotificationObserver() {
        pingService.$answerablePings
            .compactMap { $0.last?.nextPing(averagePingInterval: self.pingService.averagePingInterval) }
            .combineLatest($latestAnswer)
            .sink { [self] (nextPing, latestAnswer) in
                var nextPings = [nextPing]
                while nextPings.count < 30 {
                    let next = nextPings.last!.nextPing(averagePingInterval: pingService.averagePingInterval)
                    nextPings.append(next)
                }

                let nextPingDates = nextPings.map { $0.date }

                if let latestAnswer = latestAnswer {
                    notificationService.tryToScheduleNotifications(pings: nextPingDates, previousAnswer: latestAnswer)
                } else {
                    notificationService.tryToScheduleNotifications(pings: nextPingDates, previousAnswer: nil)
                }
            }
            .store(in: &subscribers)
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
            .map { (answerablePings, answers) -> [Date] in
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

    func getUnansweredPings(completion: @escaping (([Date]) -> Void)) {
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
        do {
            // TODO: This has a limit of 500 writes, we should ideally split tags into multiple chunks of 500
            let writeBatch = Firestore.firestore().batch()

            try unansweredPings
            .map { Answer(ping: $0, tags: tags) }
            .forEach { answer in
                let document = answerCollection.document(answer.ping.documentId)
                try writeBatch.setData(from: answer, forDocument: document)
            }

            writeBatch.commit() { [self] error in
                if let error = error {
                    alertService.present(message: "answerAllUnansweredPings \(error)")
                }
            }
        } catch {
            alertService.present(message: "answerAllUnansweredPings \(error)")
        }
    }
}

extension Store: NotificationServiceDelegate {
    func didAnswerPing(ping: Date, with text: String) {
        let tags = text.split(separator: " ").map { Tag($0) }
        let answer = Answer(ping: ping, tags: tags)
        addAnswer(answer)
    }
}
