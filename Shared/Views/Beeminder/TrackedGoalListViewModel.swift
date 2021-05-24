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
    @LazyInjected private var alertService: AlertService

    @Published private(set) var trackedGoals: [Goal] = []
    @Published private(set) var isRefreshing = false

    private var subscribers = Set<AnyCancellable>()

    init() {
        isRefreshing = true
        goalService.goalsPublisher
            .combineLatest(goalService.goalTrackersPublisher)
            .map { goals, goalTrackers in
                goals.filter { goalTrackers[$0.id] != nil }
            }
            .receive(on: DispatchQueue.main)
            .sink { [self] goals in
                trackedGoals = goals
                isRefreshing = false
            }
            .store(in: &subscribers)
    }

    func refreshGoals() {
        isRefreshing = true

        goalService.getGoals()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case let .failure(error):
                    self?.alertService.present(message: error.localizedDescription)
                case .finished:
                    self?.isRefreshing = false
                }
            }, receiveValue: {})
            .store(in: &subscribers)
    }
}
