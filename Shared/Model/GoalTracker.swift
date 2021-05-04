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
}
