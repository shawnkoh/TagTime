//
//  TrackedGoalListViewModel.swift
//  TagTime
//
//  Created by Shawn Koh on 17/5/21.
//

import Foundation
import Combine
import Beeminder
import Resolver

final class TrackedGoalListViewModel: ObservableObject {
    @LazyInjected private var goalService: GoalService

    @Published private(set) var trackedGoals: [Goal] = []

    private var subscribers = Set<AnyCancellable>()

    init() {
        goalService.goalsPublisher
            .combineLatest(goalService.goalTrackersPublisher)
            .map { goals, goalTrackers in
                goals.filter { goalTrackers[$0.id] != nil }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.trackedGoals = $0 }
            .store(in: &subscribers)
    }
}
