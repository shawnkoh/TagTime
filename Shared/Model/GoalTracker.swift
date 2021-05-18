//
//  GoalTracker.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/5/21.
//

import Foundation

struct GoalTracker: Codable {
    let tags: [Tag]
    let updatedDate: Date
    let deletedDate: Date?

    init(tags: [Tag], updatedDate: Date, deletedDate: Date? = nil) {
        self.tags = tags
        self.updatedDate = updatedDate
        self.deletedDate = deletedDate
    }
}
