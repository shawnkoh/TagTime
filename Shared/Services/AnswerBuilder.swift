//
//  AnswerBuilder.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 10/5/21.
//

import Foundation
import Combine

struct AnswerBuilder {
    enum Operation {
        // TODO: The operations should not accept the Answer model, rather, it should only accept the parameters
        // Executor should translate it to Answer, this way, we don't need to hack the updatedDate
        case create(Answer)
        case update(Answer, [Tag])
    }

    init() {}

    var operations: [Operation] = []
    var willUpdateTrackedGoals = true
    var willOverrideUpdatedDate = true

    mutating func createAnswer(_ answer: Answer) -> Self {
        operations.append(.create(answer))
        return self
    }

    mutating func updateAnswer(_ answer: Answer, tags: [Tag]) -> Self {
        operations.append(.update(answer, tags))
        return self
    }

    mutating func updateTrackedGoals(_ will: Bool) -> Self {
        self.willUpdateTrackedGoals = will
        return self
    }

    mutating func overrideUpdateDate(_ will: Bool) -> Self {
        self.willOverrideUpdatedDate = will
        return self
    }

    func execute(with executor: AnswerBuilderExecutor) -> AnyPublisher<Void, Error> {
        executor.execute(answerBuilder: self)
    }
}

protocol AnswerBuilderExecutor {
    func execute(answerBuilder: AnswerBuilder) -> AnyPublisher<Void, Error>
}
