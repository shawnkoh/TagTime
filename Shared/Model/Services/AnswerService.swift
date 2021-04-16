//
//  AnswerService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 17/4/21.
//

import Foundation
import Combine
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

final class AnswerService: ObservableObject {
    static let shared = AnswerService()

    // Solely updated by Firestore listener
    @Published private(set) var answers: [Answer] = []
    // Solely updated by publisher
    @Published private(set) var unansweredPings: [Date] = []
    // Solely updated by Firestore listener
    @Published private(set) var latestAnswer: Answer?

    private var userSubscriber: AnyCancellable = .init({})

    private var subscribers = Set<AnyCancellable>()
    private var listeners = [ListenerRegistration]()

    var answerCollection: CollectionReference? {
        AuthenticationService.shared.user?.answerCollection
    }

    init() {
        userSubscriber = AuthenticationService.shared.$user
            .receive(on: DispatchQueue.main)
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

        setupFirestoreListeners(user: user)
        setupSubscribers()
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
            .addSnapshotListener() { (snapshot, error) in
                if let error = error {
                    AlertService.shared.present(message: "setupFirestoreListeners \(error.localizedDescription)")
                }

                guard let snapshot = snapshot else {
                    AlertService.shared.present(message: "setupFirestoreListeners unable to get snapshot")
                    return
                }

                do {
                    self.latestAnswer = try snapshot.documents.first?.data(as: Answer.self)
                } catch {
                    AlertService.shared.present(message: "setupFirestoreListeners unable to decode latestAnswer")
                }
            }
            .store(in: &listeners)
    }

    private func setupSubscribers() {
        // Update unansweredPings by comparing answerablePings with answers.
        // answerablePings is maintained by PingService
        // answers is maintained by observing Firestore's answers
        // TODO: We need to find a way to minimise the number of reads for this.
        PingService.shared.$answerablePings
            .combineLatest($answers)
            .map { (answerablePings, answers) -> [Date] in
                let answeredPings = Set(answers.map { $0.ping })

                let unansweredPings = answerablePings
                    .filter { !answeredPings.contains($0.date) }
                    .map { $0.date }

                return unansweredPings
            }
            .receive(on: DispatchQueue.main)
            .sink { self.unansweredPings = $0 }
            .store(in: &subscribers)
    }


    enum AnswerError: Error {
        case notAuthenticated
    }

    func addAnswer(_ answer: Answer) -> Result<Answer, Error> {
        guard let answerCollection = answerCollection else {
            return .failure(AnswerError.notAuthenticated)
        }

        var result: Result<Answer, Error>!
        let semaphore = DispatchSemaphore(value: 0)
        do {
            try answerCollection
                .document(answer.documentId)
                .setData(from: answer) { error in
                    if let error = error {
                        result = .failure(error)
                    } else {
                        result = .success(answer)
                    }
                    semaphore.signal()
                }
        } catch {
            return .failure(error)
        }
        _ = semaphore.wait(wallTimeout: .distantFuture)

        return result
    }

    func updateAnswer(_ answer: Answer) {
        guard let answerCollection = answerCollection else {
            return
        }

        do {
            try answerCollection
                .document(answer.documentId)
                .setData(from: answer)
        } catch {
            AlertService.shared.present(message: "updateAnswer(_:) \(error)")
        }
    }

    func answerAllUnansweredPings(tags: [Tag]) {
        guard let answerCollection = answerCollection else {
            return
        }

        do {
            // TODO: This has a limit of 500 writes, we should ideally split tags into multiple chunks of 500
            let writeBatch = Firestore.firestore().batch()

            try unansweredPings
                .map { Answer(ping: $0, tags: tags) }
                .forEach { answer in
                    let document = answerCollection.document(answer.documentId)
                    try writeBatch.setData(from: answer, forDocument: document)
                }

            writeBatch.commit() { error in
                if let error = error {
                    AlertService.shared.present(message: "answerAllUnansweredPings \(error)")
                }
            }
        } catch {
            AlertService.shared.present(message: "answerAllUnansweredPings \(error)")
        }
    }
}
