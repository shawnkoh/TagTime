//
//  PingService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 8/4/21.
//

import Foundation
import Combine
import Resolver

public final class PingService {
    enum Status {
        case loading
        case loaded
    }

    var startPing: Ping

    // Average gap between pings, in seconds
    var averagePingInterval: Int

    @Published private(set) var status: Status = .loading
    @Published private(set) var answerablePings: [Ping]

    private var subscribers = Set<AnyCancellable>()

    @LazyInjected private var authenticationService: AuthenticationService

    init(averagePingInterval: Int = defaultAveragePingInterval) {
        self.averagePingInterval = averagePingInterval
        self.startPing = Self.tagTimeBirth
        self.answerablePings = []

        authenticationService.userPublisher
            .removeDuplicatesForServices()
            .sink { self.setup(user: $0) }
            .store(in: &subscribers)
    }

    private func setup(user: User) {
        changeStartDate(to: user.startDate)
    }

    // TODO: This needs to be based on the users' recent answers instead.
    // in order to support dynamic ping frequency.
    func changeStartDate(to startDate: Date) {
        status = .loading

        let now = Date()

        var cursor = Self.tagTimeBirth
        while cursor.date < startDate {
            cursor = cursor.nextPing(averagePingInterval: averagePingInterval)
        }
        self.startPing = cursor

        var pings: [Ping] = []
        while cursor.date <= now {
            pings.append(cursor)
            cursor = cursor.nextPing(averagePingInterval: averagePingInterval)
        }
        self.answerablePings = pings

        // Start looping. updateAnswerablePings does not get called when self.answerablePings is first set
        updateAnswerablePings()
    }

    private var updateTimer: Timer?

    // TODO: Test whether this works
    private func updateAnswerablePings() {
        updateTimer?.invalidate()

        guard let nextPing = answerablePings.last?.nextPing(averagePingInterval: averagePingInterval) else {
            return
        }

        let timeInterval = nextPing.date.timeIntervalSinceNow

        updateTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [self] date in
            status = .loaded
            answerablePings.append(nextPing)
            updateAnswerablePings()
        }
    }

    func nextPing(after date: Date) -> Ping {
        var cursor = startPing
        while cursor.date <= date {
            cursor = cursor.nextPing(averagePingInterval: averagePingInterval)
        }
        return cursor
    }

    func nextPing(onOrAfter date: Date) -> Ping {
        var cursor = startPing
        while cursor.date < date {
            cursor = cursor.nextPing(averagePingInterval: averagePingInterval)
        }
        return cursor
    }
}

extension PingService {
    // tagTimeBirth seed and unixtime must be paired in order for the universal schedule to work
    static let tagTimeBirth = Ping(seed: 11193462, unixtime: 1184097393, sourcePingInterval: 45 * 60)
    static let defaultAveragePingInterval = 45 * 60
}
