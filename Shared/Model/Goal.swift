//
//  Goal.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/5/21.
//

import Foundation

enum GoalType: String, Codable {
    /// Do More
    case hustler
    /// Odometer
    case biker
    /// Weight loss
    case fatloser
    /// Gain Weight
    case gainer
    /// Inbox Fewer
    case inboxer
    /// Do Less
    case drinker
    /// Full access to the underlying goal parameters
    case custom
}

struct Goal: Codable, Identifiable, Hashable {
    /// String of hex digits. We prefer using user/slug as the goal identifier, however, since we began allowing users to change slugs, this id is useful!
    let id: String
    /// The final part of the URL of the goal, used as an identifier. E.g., if user "alice" has a goal at beeminder.com/alice/weight then the goal's slug is "weight".
    let slug: String
    /// Unix timestamp of the last time this goal was updated.
    let updatedAt: Int
    /// The title that the user specified for the goal. E.g., "Weight Loss".
    let title: String
    /// The user-provided description of what exactly they are committing to.
    let fineprint: String?
    /// The name of automatic data source, if this goal has one. Will be null for manual goals.
    let autodata: String?
    /// URL for the goal's graph thumbnail image. E.g., "http://static.beeminder.com/alice/weight-thumb.png".
    let thumbUrl: String
    let goalType: GoalType
}
