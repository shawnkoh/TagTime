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

    // TODO: Find a better way to handle this
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

    func batchCreateAnswers(_ answers: [Answer]) -> Future<Void, Error> {
        Future { promise in
            guard let user = AuthenticationService.shared.user else {
                promise(.failure(AuthError.notAuthenticated))
                return
            }
            let batch = Firestore.firestore().batch()
            // TODO: This needs to be split into chunks of maximum 500 / 3
            answers.forEach { answer in
                batch.createAnswer(answer, user: user)
            }
            batch.commit() { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
    }

    func createAnswer(_ answer: Answer, user: User) -> Future<Void, Error> {
        Future { promise in
            let batch = Firestore.firestore().batch()
            batch.createAnswer(answer, user: user)

            batch.commit() { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
    }

    func createAnswer(_ answer: Answer) -> Future<Void, Error> {
        guard let user = AuthenticationService.shared.user else {
            return Future { promise in
                promise(.failure(AuthError.notAuthenticated))
            }
        }
        return createAnswer(answer, user: user)
    }

    func updateAnswer(_ answer: Answer, tags: [Tag], user: User) -> Future<Void, Error> {
        Future { promise in
            let batch = Firestore.firestore().batch()
            batch.updateAnswer(answer, tags: tags, user: user)

            batch.commit() { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
    }

    func updateAnswer(_ answer: Answer, tags: [Tag]) -> Future<Void, Error> {
        guard let user = AuthenticationService.shared.user else {
            return Future { promise in
                promise(.failure(AuthError.notAuthenticated))
            }
        }
        return updateAnswer(answer, tags: tags, user: user)
    }
}

private extension WriteBatch {
    func createAnswer(_ answer: Answer, user: User) {
        try! self.setData(from: answer, forDocument: user.answerCollection.document(answer.documentId))
        TagService.shared.registerTags(answer.tags, with: self)
    }

    func updateAnswer(_ answer: Answer, tags: [Tag], user: User) {
        let newTags = Set(tags)
        let oldTags = Set(answer.tags)
        let removedTags = Array(oldTags.subtracting(newTags))
        let addedTags = Array(newTags.subtracting(oldTags))
        try! self.setData(from: answer, forDocument: user.answerCollection.document(answer.documentId))
        TagService.shared.batchTags(register: Array(addedTags), deregister: Array(removedTags), with: self)
    }
}


#if DEBUG
extension AnswerService {
    // TODO: Deprecated. Need to implement using new removeAnswer
    func deleteAllAnswers() {
        guard let answerCollection = answerCollection else {
            return
        }
        // TODO: This has a limit of 500 writes, we should ideally split tags into multiple chunks of 500
        let writeBatch = Firestore.firestore().batch()
        answerCollection.getDocuments() { result, error in
            if let error = error {
                AlertService.shared.present(message: error.localizedDescription)
            }
            guard let result = result else {
                return
            }
            result.documents.forEach { writeBatch.deleteDocument($0.reference) }
            writeBatch.commit() { error in
                if let error = error {
                    AlertService.shared.present(message: error.localizedDescription)
                }
            }
        }
    }
}
#endif
