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
    static let writeLimitPerBatch = 500
    static let delayPerBatch = 1

    @LazyInjected private var authenticationService: AuthenticationService
    @LazyInjected private var beeminderCredentialService: BeeminderCredentialService
    @LazyInjected private var tagService: TagService
    @LazyInjected private var goalService: GoalService

    init() {}

    func execute(answerBuilder: AnswerBuilder) -> AnyPublisher<Void, Error> {
        guard answerBuilder.operations.count > 0 else {
            return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        let operations: [AnswerBuilder.Operation]
        if answerBuilder.willOverrideUpdatedDate {
            operations = overrideUpdatedDate(for: answerBuilder.operations)
        } else {
            operations = answerBuilder.operations
        }
        let batches = getBatches(from: operations)
        let batchPublishers = getBatchPublishers(from: batches)
        let mergedPublisher = getMergedPublisher(from: batchPublishers)

        guard answerBuilder.willUpdateTrackedGoals && beeminderCredentialService.credential != nil else {
            return mergedPublisher
        }

        return mergedPublisher
            .flatMap { _ in self.updateGoals(from: answerBuilder.operations) }
            .eraseToAnyPublisher()
    }

    private func overrideUpdatedDate(for operations: [AnswerBuilder.Operation]) -> [AnswerBuilder.Operation] {
        // TODO: Test whether it's necessary to remove nano second
//        // Remove nanosecond
//        let date = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date()).date!
        let date = Date()
        return operations.map { operation in
            switch operation {
            case let .create(answer):
                return .create(Answer(updatedDate: date, ping: answer.ping, tags: answer.tags))
            case let .update(answer, tags):
                return .update(Answer(updatedDate: date, ping: answer.ping, tags: answer.tags), tags)
            }
        }
    }

    private func getBatches(from operations: [AnswerBuilder.Operation]) -> [WriteBatch] {
        let firestore = Firestore.firestore()
        var batch = firestore.batch()
        var batches: [WriteBatch] = [batch]
        var count = 0

        operations.forEach { operation in
            if count >= Self.writeLimitPerBatch {
                batch = firestore.batch()
                batches.append(batch)
                count = 0
            }

            switch operation {
            case let .create(answer):
                // cost = 1 write
                batch.createAnswer(answer, user: authenticationService.user)

            case let .update(answer, tags):
                let newAnswer = Answer(updatedDate: Date(), ping: answer.ping, tags: tags)
                // cost = 1 write
                batch.createAnswer(newAnswer, user: authenticationService.user)
            }
            count += 1
        }

        getTagDeltas(from: operations).forEach { tagDelta in
            if count >= Self.writeLimitPerBatch {
                batch = firestore.batch()
                batches.append(batch)
                count = 0
            }
            tagService.registerTag(tag: tagDelta.key, batch: batch, delta: tagDelta.value)
            count += 1
        }

        return batches
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

    private func getBatchPublishers(from batches: [WriteBatch]) -> [Future<Void, Error>] {
        var count = 0
        return batches
            .map { batch -> Future<Void, Error> in
                count += 1
                return Future { promise in
                    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + .init(count * Self.delayPerBatch)) {
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
    }

    private func getMergedPublisher(from publishers: [Future<Void, Error>]) -> AnyPublisher<Void, Error> {
        Publishers
            .MergeMany(publishers)
            .collect()
            .map { _ in }
            .eraseToAnyPublisher()
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
