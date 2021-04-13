//
//  Ping.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import Foundation

struct Ping: Hashable {
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
    func nextPing(averagePingInterval: Int) -> Ping {
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

        return Ping(seed: seed, unixtime: unixtime)
    }
}
