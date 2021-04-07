//
//  Stub.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import Foundation

enum Stub {
    static let user: User = .init(id: "preview")
    static let tags: [Tag] =
        ["WORKING", "SLEEPING", "TOILETING", "EATING", "GAMING", "READING", "EXERCISING", "COOKING"]

    static let pings: [Ping] =
        [-1, -2, -3 , -5, -9, -12, -14, -15, -18, -19, -20, -24, -26, -30, -48, -50]
            .map { Ping(timeIntervalSinceNow: $0 * 60 * 60) }

    static let answers: [Answer] =
        pings.compactMap { ping in
            guard Bool.random() else {
                return nil
            }

            let chosen = (0...Int.random(in: 1...3))
                .compactMap { _ in Self.tags.randomElement() }
            let tags = Array(Set(chosen))
            return Answer(updatedDate: ping, ping: ping, tags: tags)
        }
}
