//
//  Ping.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import Foundation

struct Ping: Identifiable {
    let id: UUID
    let date: Date

    init(id: UUID = UUID(), date: Date = Date()) {
        self.id = id
        self.date = date
    }
}
