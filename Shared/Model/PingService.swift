//
//  PingService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 8/4/21.
//

import Foundation

final class PingService: ObservableObject {
    // Reference:: https://forum.beeminder.com/t/official-reference-implementation-of-the-tagtime-universal-ping-schedule/4282

    // Average gap between pings, in seconds
    var pingInterval: Int
    // Ur-ping ie the birth of Timepie/TagTime! (unixtime)
    let urping = 1184097393
    // Initial state of the random number generator
    var seed: Int
    // =7^5: Multiplier for LCG random number generator
    let ia = 16807
    // =2^31-1: Modulus used for the RNG
    let im = 2147483647

    // Above URPING is in 2007 and it's fine to jump to any later URPING/SEED pair
    // like this one in 2018 -- URPING = 1532992625, SEED = 75570 -- without
    // deviating from the universal ping schedule.

    // Global var with unixtime (in seconds) of last computed ping
    var lastPing: Int
    // Global variable that's the state of the RNG
    var state: Int

    init(pingInterval: Int = 45 * 60, seed: Int = 11193462) {
        self.pingInterval = pingInterval
        self.seed = seed
        self.lastPing = urping
        self.state = seed
    }

    // Here are the functions for generating random numbers in general:

    // Linear Congruential Generator, returns random integer in {1, ..., IM-1}.
    // This is ran0 from Numerical Recipes and has a period of ~2 billion.
    private func lcg() -> Int {
        // lcg()/IM is a U(0,1) R.V.
        state = ia * state % im
        return state
    }

    // Return a random number drawn from an exponential distribution with mean m
    private func exprand(m: Int) -> Double {
        Double(-m) * log(Double(lcg()) / Double(im))
    }

    // Every TagTime gap must be an integer number of seconds not less than 1
    private func gap() -> Int {
        Int(max(1, round(exprand(m: pingInterval))))
    }

    // Return unixtime of the next ping. First call init(t) and then call this in
    // succession to get all the pings starting with the first one after time t.
    private func nextping() -> Int {
        lastPing += gap()
        return lastPing
    }

    // Start at the beginning of time and walk forward till we hit the first ping
    // strictly after time t. Then scooch the state back a step and return the first
    // ping *before* (or equal to) t. Then we're ready to call nextping().
    func begin(t: Int) -> Int {
        // keep track of the previous values of the global variables
        var p = 0
        var s = 0
        // reset the global state
        (lastPing, state) = (urping, seed)
        // walk forward
        while lastPing <= t {
            (p, s) = (lastPing, state)
            _ = nextping()
        }
        // rewind a step
        (lastPing, state) = (p, s)
        // return most recent ping time <= t
        return lastPing
    }
}
