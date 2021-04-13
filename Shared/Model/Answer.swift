//
//  Answer.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import Foundation

public struct Answer: Identifiable, Codable {
    public let id: UUID
    public let updatedDate: Date
    public let ping: Ping
    public var tags: [Tag]

    init(id: UUID = UUID(), updatedDate: Date = Date(), ping: Ping, tags: [Tag]) {
        self.id = id
        self.updatedDate = updatedDate
        self.ping = ping
        self.tags = tags
    }
}
