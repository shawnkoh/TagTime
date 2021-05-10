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

// If we make it a struct we can't inject the services. that has to be done somewhere else.
// Will have to split it into struct AnswerBuilder and class AnswerExecuter
// For simplicity let's keep it as a mutable builder for now
final class AnswerBuilder {
    @Injected private var tagService: TagService
    @Injected private var goalService: GoalService
    @Injected private var authenticationService: AuthenticationService
    @Injected private var beeminderCredentialService: BeeminderCredentialService

    private enum Operation {
        case create(Answer)
        case update(Answer, [Tag])
    }

    init() {}

    private var operations: [Operation] = []

    func createAnswer(_ answer: Answer) -> Self {
        operations.append(.create(answer))
        return self
    }

    func updateAnswer(_ answer: Answer, tags: [Tag]) -> Self {
        operations.append(.update(answer, tags))
        return self
    }

    // TODO: Handle goal updates
    func execute() -> AnyPublisher<Void, Error> {
        guard operations.count > 0 else {
            return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        // TODO: Chunk this if it exceeds 500 writes
        // can do this by summing the cost of each operation, preferably in a different function
        let batch = Firestore.firestore().batch()
        operations.forEach { operation in
            switch operation {
            case let .create(answer):
                batch.createAnswer(answer, user: authenticationService.user)

            case let .update(answer, tags):
                let newAnswer = Answer(updatedDate: Date(), ping: answer.ping, tags: tags)
                batch.createAnswer(newAnswer, user: authenticationService.user)
            }
        }

        getTagDeltas(from: operations).forEach { tagDelta in
            if tagDelta.value > 0 {
                tagService.registerTags([tagDelta.key], with: batch, increment: tagDelta.value)
            } else if tagDelta.value < 0 {
                tagService.deregisterTags([tagDelta.key], with: batch, decrement: tagDelta.value)
            }
            // 0 is ignored because it has no change
        }

        let writePublisher = Future<Void, Error> { promise in
            batch.commit() { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()

        guard beeminderCredentialService.credential != nil else {
            return writePublisher
        }

        return writePublisher
            .flatMap { self.updateGoals(from: self.operations) }
            .map { _ in }
            .eraseToAnyPublisher()
    }

    private func getTagDeltas(from operations: [Operation]) -> [Tag: Int] {
        var tagDeltas: [Tag: Int] = [:]

        func addTag(_ tag: Tag) {
            if let delta = tagDeltas[tag] {
                tagDeltas[tag] = delta + 1
            } else {
                tagDeltas[tag] = 1
            }
        }

        func removeTag(_ tag: Tag) {
            if let delta = tagDeltas[tag] {
                tagDeltas[tag] = delta - 1
            } else {
                tagDeltas[tag] = -1
            }
        }

        operations.forEach { operation in
            switch operation {
            case let .create(answer):
                answer.tags.forEach(addTag)

            case let .update(answer, tags):
                let newTags = Set(tags)
                let oldTags = Set(answer.tags)
                let addedTags = Array(newTags.subtracting(oldTags))
                let removedTags = Array(oldTags.subtracting(newTags))
                addedTags.forEach(addTag)
                removedTags.forEach(removeTag)
            }
        }
        return tagDeltas
    }

    private func updateGoals(from operations: [Operation]) -> AnyPublisher<Void, Error> {
        let operationPublishers = operations
            .map { operation -> AnyPublisher<Void, Error> in
                switch operation {
                case let .create(answer):
                    return self.goalService.updateTrackedGoals(answer: answer)
                case let .update(answer, tags):
                    let answer = Answer(ping: answer.ping, tags: tags)
                    return self.goalService.updateTrackedGoals(answer: answer)
                }
            }

        return Publishers.MergeMany(operationPublishers)
            .collect()
            .map { _ in }
            .eraseToAnyPublisher()
    }
}

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
        answers = []
        latestAnswer = nil

        setupFirestoreListeners(user: user)
    }

    private func setupFirestoreListeners(user: User) {
        user.answerCollection
            .order(by: "ping", descending: true)
            .limit(to: PingService.answerablePingCount)
            .addSnapshotListener { [self] (snapshot, error) in
                if let error = error {
                    alertService.present(message: "setupFirestoreListeners \(error.localizedDescription)")
                }

                // TODO: this is problematic for pagination because it overwrites all the answers.
                answers = snapshot?.documents.compactMap { try? $0.data(as: Answer.self) } ?? []
                latestAnswer = answers.first
            }
            .store(in: &listeners)
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
