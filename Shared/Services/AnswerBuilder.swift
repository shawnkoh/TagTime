//
//  AnswerBuilder.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 10/5/21.
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

private extension WriteBatch {
    func createAnswer(_ answer: Answer, user: User) {
        try! self.setData(from: answer, forDocument: user.answerCollection.document(answer.id))
    }
}
