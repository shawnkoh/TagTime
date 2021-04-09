//
//  PingService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 8/4/21.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Firebase

final class Randomer {
    // Average gap between pings, in seconds
    private let averagePingInterval: Int

    // rngState is only used to calculate a random number.
    // it doesn't care about previous
    private var rngState: Int

    private(set) var lastPing: Int

    // =7^5: Multiplier for LCG random number generator
    private let ia = 16807
    // =2^31-1: Modulus used for the RNG
    private let im = 2147483647

    init(rngSeed: Int, lastPing: Int, averagePingInterval: Int) {
        self.rngState = rngSeed
        self.lastPing = lastPing
        self.averagePingInterval = averagePingInterval
    }

    // Linear Congruential Generator, returns random integer in {1, ..., IM-1}.
    // This is ran0 from Numerical Recipes and has a period of ~2 billion.
    private func lcg() -> Int {
        // lcg()/IM is a U(0,1) R.V.
        rngState = ia * rngState % im
        return rngState
    }

    // Return a random number drawn from an exponential distribution with mean
    private func exprand(mean: Int) -> Double {
        Double(-mean) * log(Double(lcg()) / Double(im))
    }

    // Every TagTime gap must be an integer number of seconds not less than 1
    private func gap() -> Int {
        Int(max(1, round(exprand(mean: averagePingInterval))))
    }

    // Return unixtime of the next ping. First call init(t) and then call this in
    // succession to get all the pings starting with the first one after time t.
    func nextPing() -> Int {
        lastPing += gap()
        return lastPing
    }
}

final class Pinger {
    // Average gap between pings, in seconds
    var averagePingInterval = 45 * 60

    // tagTimeBirthTime and tagTimeBirthSeed must be paired in order for the universal schedule to work
    /// The birth of Timepie/TagTime! (unixtime)
    /// Used as the first ping.
    let tagTimeBirthTime = 1184097393
    let tagTimeBirthSeed = 11193462

    func makeRandomer() -> Randomer {
        .init(rngSeed: tagTimeBirthSeed, lastPing: tagTimeBirthTime, averagePingInterval: averagePingInterval)
    }

    func nextPing() -> Ping {
        let randomer = makeRandomer()
        let now = Date()
        var nextPing: TimeInterval = 0
        while nextPing <= now.timeIntervalSince1970 {
            nextPing = TimeInterval(randomer.nextPing())
        }
        return Date(timeIntervalSince1970: nextPing)
    }

    func nextPings(count: Int) -> [Ping] {
        var result = [Ping]()
        let randomer = makeRandomer()
        return result
    }

    func unansweredPings(user: User) -> [Ping] {
        var result = [Ping]()
        // alternatively, we keep the Answer data structure on firestore
        // then, we store the date that the user first begins using TagTime onto firebase.
        // using that date, we can compare the Answers collection with the data.
        // this is problematic. if you rely only on the latest answer, then what if the user closes the app after answering a Ping?
//        Firestore.firestore()
//            .collection("users")
//            .document(user.id)
//            .collection("answers")
//            .order(by: "ping", descending: true)
//            .whereField("ping", isGreaterThanOrEqualTo: user.startDate)
//            .getDocuments() { (result, error) in
//                do {
//                    guard let answer = try result?.documents.first?.data(as: Answer.self) else {
//                        return
//                    }
//                    let latestPing = answer.ping
//                } catch {
//                }
//            }
        // find the last ping from Firestore
        // walk forward until the randomly generated ping is greater than Firestore's ping
        // add that ping to an array
        // walk forward until the next ping is less than the current time, and add every ping into the result
        let randomer = makeRandomer()
        return result
    }
}

final class PingService: ObservableObject {
    // Reference:: https://forum.beeminder.com/t/official-reference-implementation-of-the-tagtime-universal-ping-schedule/4282

    // Average gap between pings, in seconds
    var averagePingInterval: Int
    /// The birth of Timepie/TagTime! (unixtime)
    let tagTimeBirthTime = 1184097393
    // Initial state of the random number generator
    var seed: Int
    // =7^5: Multiplier for LCG random number generator
    let ia = 16807
    // =2^31-1: Modulus used for the RNG
    let im = 2147483647

    // tagTimeBirthTime is in 2007 and it's fine to jump to any later tagTimeBirthTime/SEED pair
    // like this one in 2018 -- tagTimeBirthTime = 1532992625, SEED = 75570
    // without deviating from the universal ping schedule.

    // Global var with unixtime (in seconds) of last computed ping
    var lastPing: Int
    // Global variable that's the state of the RNG
    var state: Int

    init(averagePingInterval: Int = 45 * 60, seed: Int = 11193462) {
        self.averagePingInterval = averagePingInterval
        self.seed = seed
        self.lastPing = tagTimeBirthTime
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
        Int(max(1, round(exprand(m: averagePingInterval))))
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
        (lastPing, state) = (tagTimeBirthTime, seed)
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
