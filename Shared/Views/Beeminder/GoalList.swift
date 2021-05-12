//
//  GoalList.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/5/21.
//

import SwiftUI
import Resolver
import Combine
import Beeminder

final class GoalListViewModel: ObservableObject {
    @Injected private var goalService: GoalService
    private var subscribers = Set<AnyCancellable>()

    @Published private(set) var trackedGoals: [Goal] = []

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

struct GoalList: View {
    @StateObject private var viewModel = GoalListViewModel()

    var body: some View {
        VStack(alignment: .leading) {
            PageTitle(title: "Goal List", subtitle: "Don't let the bee sting!")

            ForEach(viewModel.trackedGoals) { goal in
                Text(goal.slug)
            }
        }
    }
}

struct GoalList_Previews: PreviewProvider {
    static var previews: some View {
        GoalList()
    }
}
