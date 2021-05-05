//
//  Goal.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/5/21.
//

import Foundation
import SwiftUI

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
    /// Unix timestamp of derailment. When you'll be off the road if nothing is reported.
    let losedate: Int
    /// The integer number of safe days. If it's a beemergency this will be zero.
    // This looks to always be non-nil used nil for defensive coding purpose
    let safebuf: Int?
    /// Amount pledged (USD) on the goal.
    let pledge: Double?
    /// Seconds by which your deadline differs from midnight. Negative is before midnight, positive is after midnight.
    /// Allowed range is -17*3600 to 6*3600 (7am to 6am).
    let deadline: Int

    /// Goal units, like "hours" or "pushups" or "pages".
    let gunits: String

    /// Not sure whether this is safe to use. Seems to be the bare minimum units required to finish before the losedate.
    // TODO: Check with Daniel.
    let baremin: String
}

extension Goal {
    // Retrieved from https://api.beeminder.com/?ruby#attributes-2
    var color: Color {
        guard let safebuf = safebuf else {
            return .gray
        }
        if safebuf < 1 {
            return .red
        } else if safebuf < 2 {
            return .orange
        } else if safebuf < 3 {
            return .blue
        } else if safebuf < 7 {
            return .green
        } else {
            return .gray
        }
    }

    var derailDate: Date {
        .init(timeIntervalSince1970: Double(losedate))
    }

    func dueInDescription(currentTime: Date) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: currentTime, to: derailDate)!
    }

    var isTrackable: Bool {
        // TODO: Implement this
        true
    }
}
