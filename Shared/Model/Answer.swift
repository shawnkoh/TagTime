//
//  Answer.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import Foundation

public struct Answer: Identifiable, Codable {
    // TODO: Why do I need an ID for? Isn't the documentId already the ID?
    public let id: UUID
    public let updatedDate: Date
    public let ping: Date
    public var tags: [Tag]

    var documentId: String {
        ping.timeIntervalSince1970.description
    }

    init(id: UUID = UUID(), updatedDate: Date = Date(), ping: Date, tags: [Tag]) {
        self.id = id
        self.updatedDate = updatedDate
        self.ping = ping
        self.tags = tags
    }
}

extension Answer {
    var tagDescription: String {
        tags.joined(separator: " ")
    }
}
