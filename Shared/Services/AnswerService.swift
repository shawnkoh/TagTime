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

final class AnswerBuilder {
    @Injected private var answerService: AnswerService
    @Injected private var tagService: TagService
    @Injected private var goalService: GoalService
    @Injected private var alertService: AlertService
    @Injected private var authenticationService: AuthenticationService

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

        let tagDeltas = getTagDeltas(from: operations)

        tagDeltas.forEach { tagDelta in
            if tagDelta.value > 0 {
                tagService.registerTags([tagDelta.key], with: batch, increment: tagDelta.value)
            } else if tagDelta.value < 0 {
                tagService.deregisterTags([tagDelta.key], with: batch, decrement: tagDelta.value)
            }
            // 0 is ignored because it has no change
        }

        return Future { promise in
            batch.commit() { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func getTagDeltas(from operations: [Operation]) -> [Tag: Int] {
        var tagDeltas: [Tag: Int] = [:]
        operations.forEach { operation in
            switch operation {
            case let .create(answer):
                answer.tags.forEach { tag in
                    if let delta = tagDeltas[tag] {
                        tagDeltas[tag] = delta + 1
                    } else {
                        tagDeltas[tag] = 1
                    }
                }

            case let .update(answer, tags):
                let newTags = Set(tags)
                let oldTags = Set(answer.tags)
                let removedTags = Array(oldTags.subtracting(newTags))
                let addedTags = Array(newTags.subtracting(oldTags))

                addedTags.forEach { tag in
                    if let delta = tagDeltas[tag] {
                        tagDeltas[tag] = delta + 1
                    } else {
                        tagDeltas[tag] = 1
                    }
                }

                removedTags.forEach { tag in
                    if let delta = tagDeltas[tag] {
                        tagDeltas[tag] = delta - 1
                    } else {
                        tagDeltas[tag] = -1
                    }
                }
            }
        }
        return tagDeltas
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
