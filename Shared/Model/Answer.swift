//
//  Answer.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import Foundation

public struct Answer: Identifiable, Codable, Hashable {
    public let updatedDate: Date
    public let ping: Date
    public var tags: [Tag]

    public var id: String {
        ping.timeIntervalSince1970.description
    }

    init(updatedDate: Date = Date(), ping: Date, tags: [Tag]) {
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
