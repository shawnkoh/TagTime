//
//  FirestoreAnswerBuilderExecutor.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 12/5/21.
//

import Foundation
import Combine
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import Resolver

final class FirestoreAnswerBuilderExecutor: AnswerBuilderExecutor {
    @LazyInjected private var tagService: TagService
    @LazyInjected private var goalService: GoalService
    @LazyInjected private var authenticationService: AuthenticationService
    @LazyInjected private var beeminderCredentialService: BeeminderCredentialService

    init() {}

    // TODO: Handle goal updates
    func execute(answerBuilder: AnswerBuilder) -> AnyPublisher<Void, Error> {
        guard answerBuilder.operations.count > 0 else {
            return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        // TODO: Chunk this if it exceeds 500 writes
        // can do this by summing the cost of each operation, preferably in a different function
        let batch = Firestore.firestore().batch()
        answerBuilder.operations.forEach { operation in
            switch operation {
            case let .create(answer):
                batch.createAnswer(answer, user: authenticationService.user)

            case let .update(answer, tags):
                let newAnswer = Answer(updatedDate: Date(), ping: answer.ping, tags: tags)
                batch.createAnswer(newAnswer, user: authenticationService.user)
            }
        }

        getTagDeltas(from: answerBuilder.operations).forEach { tagDelta in
            tagService.registerTags([tagDelta.key], with: batch, delta: tagDelta.value)
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
            .flatMap { self.updateGoals(from: answerBuilder.operations) }
            .map { _ in }
            .eraseToAnyPublisher()
    }

    private func getTagDeltas(from operations: [AnswerBuilder.Operation]) -> [Tag: Int] {
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

    private func updateGoals(from operations: [AnswerBuilder.Operation]) -> AnyPublisher<Void, Error> {
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
