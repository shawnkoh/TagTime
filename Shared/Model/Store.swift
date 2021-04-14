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

    let pingService = PingService(averagePingInterval: PingService.defaultAveragePingInterval)
    let notificationService = NotificationService()
    let authenticationService = AuthenticationService()

    var settingService = SettingService()

    var alertService = AlertService()

    private var userSubscriber: AnyCancellable = .init({})

    private var subscribers = Set<AnyCancellable>()
    private var listeners = [ListenerRegistration]()

    init() {
        notificationService.delegate = self
        userSubscriber = authenticationService.$user
            .sink { self.setup(user: $0) }
    }

    private func setup(user: User?) {
        listeners.forEach { $0.remove() }
        listeners = []
        subscribers.forEach { $0.cancel() }
        subscribers = []

        guard let user = user else {
            return
        }

        pingService.changeStartDate(to: user.startDate)

        setupFirestoreListeners(user: user)
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

    private func setupFirestoreListeners(user: User) {
        // TODO: We should not be observing the entire answer collection
        // Rather, we should only observe a paginated version for displaying Logbook.
        // But take note that if you change this, you also need to implement a snapshot listener for maintaining unansweredPings
        // The most ideal solution would be to have a dedicated snapshot listener for every use case, but for now, this will do.
        // It's a quick hack but at the cost of incurring many Firestore reads
        user.answerCollection
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

        user.answerCollection
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
        settingService.$averagePingInterval
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
        guard let user = authenticationService.user else {
            return
        }

        do {
            try user.answerCollection
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

    func updateAnswer(_ answer: Answer) {
        guard let user = authenticationService.user else {
            return
        }

        do {
            try user.answerCollection
                .document(answer.ping.documentId)
                .setData(from: answer)
        } catch {
            alertService.present(message: "updateAnswer(_:) \(error)")
        }
    }

    func answerAllUnansweredPings(tags: [Tag]) {
        guard let user = authenticationService.user else {
            return
        }

        do {
            // TODO: This has a limit of 500 writes, we should ideally split tags into multiple chunks of 500
            let writeBatch = Firestore.firestore().batch()

            try unansweredPings
                .map { Answer(ping: $0, tags: tags) }
                .forEach { answer in
                    let document = user.answerCollection.document(answer.ping.documentId)
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
