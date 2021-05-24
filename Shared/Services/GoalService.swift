//
//  File.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/5/21.
//

import Foundation
import Combine
import Beeminder

protocol GoalService {
    var goals: [Goal] { get }
    var goalsPublisher: Published<[Goal]>.Publisher { get }
    var goalTrackers: [String: GoalTracker] { get }
    var goalTrackersPublisher: Published<[String: GoalTracker]>.Publisher { get }

    func trackGoal(_ goal: Goal) -> Future<Void, Error>
    func untrackGoal(_ goal: Goal) -> Future<Void, Error>
    func trackTags(_ tags: [Tag], for goal: Goal) -> Future<Void, Error>
    func updateTrackedGoals(answer: Answer) -> AnyPublisher<Void, Error>
    func getGoals() -> AnyPublisher<Void, Error>
}
