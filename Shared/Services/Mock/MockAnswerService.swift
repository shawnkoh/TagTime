//
//  MockAnswerService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 12/5/21.
//

import Foundation
import Combine
import Resolver

final class MockAnswerService: AnswerService {
    @LazyInjected private var authenticationService: AuthenticationService
    @LazyInjected private var pingService: PingService

    @Published private(set) var answers: [String: Answer] = [:]
    var answersPublisher: Published<[String: Answer]>.Publisher { $answers }

    @Published private(set) var latestAnswer: Answer?
    var latestAnswerPublisher: Published<Answer?>.Publisher { $latestAnswer }

    @Published private(set) var hasLoadedAllAnswers: Bool = false

    var hasLoadedAllAnswersPublisher: Published<Bool>.Publisher { $hasLoadedAllAnswers }

    func getMoreCachedAnswers() {
        // TODO:
    }

    private var subscribers = Set<AnyCancellable>()

    init() {
        authenticationService.userPublisher
            .removeDuplicatesForServices()
            .sink { [self] user in
                answers = [:]
                pingService.answerablePings.suffix(10).forEach { ping in
                    let tag = ["wasteman", "netflix", "yoga", "exercise"].randomElement()!
                    let answer = Answer(ping: ping.date, tags: [tag])
                    answers[answer.id] = answer
                }
                latestAnswer = answers.values.first!
            }
            .store(in: &subscribers)
    }

    #if DEBUG
    func deleteAllAnswers() {
        answers = [:]
        latestAnswer = nil
    }
    #endif
}
