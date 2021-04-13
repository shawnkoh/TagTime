//
//  PingService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 8/4/21.
//

import Foundation

struct Png: Hashable {
    let seed: Int
    let unixtime: Int

    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(unixtime))
    }

    // =7^5: Multiplier for LCG random number generator
    private let ia = 16807
    // =2^31-1: Modulus used for the RNG
    private let im = 2147483647

    init(seed: Int, unixtime: Int) {
        self.seed = seed
        self.unixtime = unixtime
    }

    /// Returns the next ping.
    /// averagePingInterval: Average gap between pings, in seconds
    func nextPing(averagePingInterval: Int) -> Png {
        // Reference:: https://forum.beeminder.com/t/official-reference-implementation-of-the-tagtime-universal-ping-schedule/4282
        // Linear Congruential Generator, returns random integer in {1, ..., IM-1}.
        // This is ran0 from Numerical Recipes and has a period of ~2 billion.
        // lcg()/IM is a U(0,1) R.V.
        let seed = ia * self.seed % im

        // Return a random number drawn from an exponential distribution with mean
        let exprand = Double(-averagePingInterval) * log(Double(seed) / Double(im))

        // Every TagTime gap must be an integer number of seconds not less than 1
        let gap = Int(max(1, round(exprand)))
        let unixtime = self.unixtime + gap

        return Png(seed: seed, unixtime: unixtime)
    }
}

final class PingService: ObservableObject {
    let startPing: Png

    // Average gap between pings, in seconds
    var averagePingInterval: Int

    // Solely updated by updateAnswerablePings
    @Published private(set) var answerablePings: [Png] {
        didSet {
            updateAnswerablePings()
        }
    }

    init(startDate: Date, averagePingInterval: Int = defaultAveragePingInterval) {
        self.averagePingInterval = averagePingInterval
        let now = Date()

        var cursor = Self.tagTimeBirth
        while cursor.date < startDate {
            cursor = cursor.nextPing(averagePingInterval: averagePingInterval)
        }
        self.startPing = cursor

        var pings: [Png] = []
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
            answerablePings.append(nextPing)
            updateAnswerablePings()
        }
    }

    func nextPing(after date: Date) -> Png {
        var cursor = startPing
        while cursor.date <= date {
            cursor = cursor.nextPing(averagePingInterval: averagePingInterval)
        }
        return cursor
    }

    func nextPing(onOrAfter date: Date) -> Png {
        var cursor = startPing
        while cursor.date < date {
            cursor = cursor.nextPing(averagePingInterval: averagePingInterval)
        }
        return cursor
    }

    func nextPings(count: Int) -> [Png] {
        guard count > 0 else {
            return []
        }

        let now = Date()
        let nextPing = self.nextPing(after: now)
        var result = [nextPing]
        while result.count < count {
            result.append(result.last!.nextPing(averagePingInterval: averagePingInterval))
        }
        return result
    }
}

extension PingService {
    // tagTimeBirth seed and unixtime must be paired in order for the universal schedule to work
    static let tagTimeBirth = Png(seed: 11193462, unixtime: 1184097393)
    static let defaultAveragePingInterval = 45 * 60
}
