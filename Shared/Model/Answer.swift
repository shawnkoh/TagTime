//
//  Answer.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import Foundation

struct Answer: Identifiable {
    let id: UUID
    let updatedDate: Date
    let ping: Ping
    var tags: [Tag]

    init(id: UUID = UUID(), updatedDate: Date = Date(), ping: Ping, tags: [Tag]) {
        self.id = id
        self.updatedDate = updatedDate
        self.ping = ping
        self.tags = tags
    }
}
