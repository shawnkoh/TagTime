//
//  Stub.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import Foundation

enum Stub {
    static let tags: [Tag] =
        ["WORKING", "SLEEPING", "TOILETING", "EATING", "GAMING", "READING", "EXERCISING", "COOKING"]
            .map { Tag(name: $0) }

    static let pings: [Ping] =
        [-1, -2, -3 , -5, -9, -12, -14, -15, -18, -19, -20, -24, -26, -30, -48, -50]
            .map { Ping(date: Date(timeIntervalSinceNow: $0 * 60 * 60)) }

    static let answers: [Answer] =
        pings.map { ping in
            let chosen = (0...Int.random(in: 1...3))
                .compactMap { _ in Self.tags.randomElement() }
            let tags = Array(Set(chosen))
            return Answer(updatedDate: ping.date, ping: ping, tags: tags)
        }
}
