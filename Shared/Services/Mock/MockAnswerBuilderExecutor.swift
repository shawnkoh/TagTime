//
//  MockAnswerBuilderExecutor.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 12/5/21.
//

import Foundation
import Combine

final class MockAnswerBuilderExecutor: AnswerBuilderExecutor {
    func execute(answerBuilder: AnswerBuilder) -> AnyPublisher<Void, Error> {
        // TODO:
        Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}
