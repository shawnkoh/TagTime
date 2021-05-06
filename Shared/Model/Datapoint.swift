//
//  Datapoint.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 6/5/21.
//

import Foundation

struct Datapoint: Codable, Identifiable, Hashable {
    /// A unique ID, used to identify a datapoint when deleting or editing it.
    let id: String
    /// The unix time (in seconds) of the datapoint.
    let timestamp: Int
    /// The date of the datapoint (e.g., "20150831"). Sometimes timestamps are surprising due to goal deadlines, so if you're looking at Beeminder data, you're probably interested in the daystamp.
    let daystamp: String
    /// The value, e.g., how much you weighed on the day indicated by the timestamp.ing
    let value: Double
    /// An optional comment about the datapoint.
    let comment: String
    /// The unix time that this datapoint was entered or last updated.
    let updatedAt: Int
    /// If a datapoint was created via the API and this parameter was included, it will be echoed back.
    let requestid: String?
}
