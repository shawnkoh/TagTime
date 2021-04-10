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
    // Average gap between pings, in seconds
    var averagePingInterval: Int

    init(averagePingInterval: Int = defaultAveragePingInterval) {
        self.averagePingInterval = averagePingInterval
    }

    func nextPing(after date: Date) -> Png {
        var cursor = PingService.tagTimeBirth
        while cursor.date <= date {
            cursor = cursor.nextPing(averagePingInterval: averagePingInterval)
        }
        return cursor
    }

    func nextPing(onOrAfter date: Date) -> Png {
        var cursor = PingService.tagTimeBirth
        while cursor.date < date {
            cursor = cursor.nextPing(averagePingInterval: averagePingInterval)
        }
        return cursor
    }

    func nextPing() -> Png {
        nextPing(after: Date())
    }

    func nextPings(count: Int) -> [Png] {
        guard count > 0 else {
            return []
        }

        let nextPing = self.nextPing()
        var result = [nextPing]
        while result.count < count {
            result.append(result.last!.nextPing(averagePingInterval: averagePingInterval))
        }
        return result
    }

    func answerablePings(startDate: Date) -> [Png] {
        let now = Date()
        let firstPing = nextPing(onOrAfter: startDate)

        var pings = [firstPing]
        var cursor = firstPing
        while cursor.date <= now {
            pings.append(cursor)
            cursor = cursor.nextPing(averagePingInterval: averagePingInterval)
        }
        return pings
    }

    func unansweredPings(user: User, completion: @escaping (([Ping]) -> Void)) {
        let now = Date()
        Firestore.firestore()
            .collection("users")
            .document(user.id)
            .collection("answers")
            .order(by: "ping", descending: true)
            .whereField("ping", isGreaterThanOrEqualTo: user.startDate)
            // TODO: We should probably filter this even more to not incur so many reads.
            .whereField("ping", isLessThanOrEqualTo: now)
            .getDocuments() { (snapshot, error) in
                guard let snapshot = snapshot else {
                    print("returned")
                    // TODO: Log this
                    return
                }
                do {
                    let answerablePings = self.answerablePings(startDate: user.startDate)
                        .map { $0.date }
                    var answerablePingSet = Set(answerablePings)
                    try snapshot.documents
                        .compactMap { try $0.data(as: Answer.self) }
                        .map { $0.ping }
                        .forEach { answerablePingSet.remove($0) }
                    let result = answerablePingSet.sorted()
                    completion(result)
                } catch {
                    // TODO: Log this
                    print("error", error)
                }
            }
    }
}

extension PingService {
    // tagTimeBirthTime and tagTimeBirthSeed must be paired in order for the universal schedule to work
    static let tagTimeBirth = Png(seed: 11193462, unixtime: 1184097393)
    static let defaultAveragePingInterval = 45 * 60
}
