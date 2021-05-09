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
import Resolver

final class AnswerService: ObservableObject {
    // Solely updated by Firestore listener
    // Sorted in descending order
    @Published private(set) var answers: [Answer] = []
    // Solely updated by Firestore listener
    @Published private(set) var latestAnswer: Answer?

    private var userSubscriber: AnyCancellable = .init({})

    private var subscribers = Set<AnyCancellable>()
    private var listeners = [ListenerRegistration]()

    @Injected private var authenticationService: AuthenticationService
    @Injected private var goalService: GoalService
    @Injected private var tagService: TagService
    @Injected private var alertService: AlertService

    private var user: User {
        authenticationService.user
    }

    private var answerCollection: CollectionReference {
        user.answerCollection
    }

    init() {
        userSubscriber = authenticationService.$user
            .sink { self.setup(user: $0) }
    }

    private func setup(user: User) {
        listeners.forEach { $0.remove() }
        listeners = []
        subscribers.forEach { $0.cancel() }
        subscribers = []

        setupFirestoreListeners(user: user)
    }

    private func setupFirestoreListeners(user: User) {
        user.answerCollection
            .order(by: "ping", descending: true)
            .limit(to: PingService.answerablePingCount)
            .addSnapshotListener() { [self] (snapshot, error) in
                if let error = error {
                    alertService.present(message: "setupFirestoreListeners \(error.localizedDescription)")
                }

                guard let snapshot = snapshot else {
                    alertService.present(message: "setupFirestoreListeners unable to get snapshot")
                    return
                }

                do {
                    // TODO: this is problematic for pagination because it overwrites all the answers.
                    answers = try snapshot.documents.compactMap { try $0.data(as: Answer.self) }
                    latestAnswer = answers.first
                } catch {
                    alertService.present(message: "setupFirestoreListeners unable to decode latestAnswer")
                }
            }
            .store(in: &listeners)
    }

    // TODO: This needs to be split into chunks
    func batchAnswerPings(pingDates: [Date], tags: [Tag]) -> Future<Void, Error> {
        Future { promise in
            let batch = Firestore.firestore().batch()
            let answers = pingDates.map { Answer(ping: $0, tags: tags) }
            answers.forEach { batch.createAnswer($0, user: self.user) }
            self.tagService.registerTags(tags, with: batch, increment: answers.count)

            batch.commit() { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
    }

    // Not used at the moment. But useful for import.
    func batchCreateAnswers(_ answers: [Answer]) -> Future<Void, Error> {
        Future { promise in
            let batch = Firestore.firestore().batch()
            // TODO: This needs to be split into chunks of maximum 500 / 3
            answers.forEach { answer in
                batch.createAnswer(answer, user: self.user)
                self.tagService.registerTags(answer.tags, with: batch)
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

    func createAnswer(_ answer: Answer) -> Future<Void, Error> {
        Future { promise in
            let batch = Firestore.firestore().batch()
            batch.createAnswer(answer, user: self.user)
            self.tagService.registerTags(answer.tags, with: batch)

            batch.commit() { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
    }

    func createAnswerAndUpdateTrackedGoals(_ answer: Answer) -> AnyPublisher<Void, Error> {
        createAnswer(answer)
            .flatMap { _ -> AnyPublisher<Void, Error> in
                self.goalService.updateTrackedGoals(answer: answer)
            }
            .eraseToAnyPublisher()
    }

    func updateAnswer(_ answer: Answer, tags: [Tag]) -> Future<Void, Error> {
        Future { promise in
            let batch = Firestore.firestore().batch()
            let newTags = Set(tags)
            let oldTags = Set(answer.tags)
            let removedTags = Array(oldTags.subtracting(newTags))
            let addedTags = Array(newTags.subtracting(oldTags))
            let newAnswer = Answer(updatedDate: Date(), ping: answer.ping, tags: tags)
            batch.createAnswer(newAnswer, user: self.user)
            self.tagService.registerTags(Array(addedTags), with: batch)
            self.tagService.deregisterTags(Array(removedTags), with: batch)

            batch.commit() { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
    }
}

private extension User {
    var answerCollection: CollectionReference {
        userDocument.collection("answers")
    }
}

private extension WriteBatch {
    func createAnswer(_ answer: Answer, user: User) {
        try! self.setData(from: answer, forDocument: user.answerCollection.document(answer.id))
    }
}


#if DEBUG
extension AnswerService {
    // TODO: Deprecated. Need to implement using new removeAnswer
    func deleteAllAnswers() {
        // TODO: This has a limit of 500 writes, we should ideally split tags into multiple chunks of 500
        let writeBatch = Firestore.firestore().batch()
        answerCollection.getDocuments() { result, error in
            if let error = error {
                self.alertService.present(message: error.localizedDescription)
            }
            guard let result = result else {
                return
            }
            result.documents.forEach { writeBatch.deleteDocument($0.reference) }
            writeBatch.commit() { error in
                if let error = error {
                    self.alertService.present(message: error.localizedDescription)
                }
            }
        }
    }
}
#endif
