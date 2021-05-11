//
//  AnswerablePingService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 11/5/21.
//

import Foundation
import Combine
import Resolver

final class AnswerablePingService {
    @Injected private var answerService: AnswerService
    @Injected private var pingService: PingService

    private var subscribers = Set<AnyCancellable>()

    @Published private(set) var unansweredPings: [Date] = []

    init() {
        setupSubscribers()
    }

    private func setupSubscribers() {
        // Update unansweredPings by comparing answerablePings with answers.
        // answerablePings is maintained by PingService
        // answers is maintained by observing Firestore's answers
        // TODO: Consider adding pagination for this
        pingService.$answerablePings
            .map { $0.suffix(Self.answerablePingCount) }
            .combineLatest(
                answerService.answersPublisher
                    .map { answers in
                        answers
                            .map { $0.value }
                            .sorted { $0.ping > $1.ping }
                    }
                    .map { $0.prefix(Self.answerablePingCount) }
                    .map { $0.map { $0.ping }}
                    .map { Set($0) }
            )
            .map { (answerablePings, answeredPings) -> [Date] in
                answerablePings
                    .filter { !answeredPings.contains($0.date) }
                    .map { $0.date }
            }
            .sink { self.unansweredPings = $0 }
            .store(in: &subscribers)
    }
}

extension AnswerablePingService {
    // 2 days worth of pings = 2 * 24 * 60 / 45
    // TODO: This should not be here because it forms a cyclic dependency between AnswerablePingService and AnswerService
    static let answerablePingCount = 64
}
