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
    // 2 days worth of pings = 2 * 24 * 60 / 45
    static let answerablePingCount = 64

    // Solely updated by Firestore listener
    // Sorted in descending order
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
        user.answerCollection
            .order(by: "ping", descending: true)
            .limit(to: Self.answerablePingCount)
            .addSnapshotListener() { [self] (snapshot, error) in
                if let error = error {
                    AlertService.shared.present(message: "setupFirestoreListeners \(error.localizedDescription)")
                }

                guard let snapshot = snapshot else {
                    AlertService.shared.present(message: "setupFirestoreListeners unable to get snapshot")
                    return
                }

                do {
                    // TODO: this is problematic for pagination because it overwrites all the answers.
                    answers = try snapshot.documents.compactMap { try $0.data(as: Answer.self) }
                    latestAnswer = answers.first
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
        // TODO: Consider adding pagination for this
        PingService.shared
            .$answerablePings
            .map { $0.suffix(Self.answerablePingCount) }
            .combineLatest(
                $answers
                    .map { $0.prefix(Self.answerablePingCount) }
                    .map { $0.map { $0.ping }}
                    .map { Set($0) }
            )
            .map { (answerablePings, answeredPings) -> [Date] in
                answerablePings
                    .filter { !answeredPings.contains($0.date) }
                    .map { $0.date }
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
