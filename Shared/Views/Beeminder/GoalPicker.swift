//
//  GoalPicker.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/5/21.
//

import SwiftUI
import Resolver
import Beeminder
import Combine

final class GoalPickerViewModel: ObservableObject {
    @LazyInjected private var goalService: GoalService
    @LazyInjected private var alertService: AlertService

    @Published private(set) var untrackedGoals: [Goal] = []

    private var subscribers = Set<AnyCancellable>()

    init() {
        goalService.goalsPublisher
            .combineLatest(goalService.goalTrackersPublisher)
            .map { goals, goalTrackers in
                goals.filter { goalTrackers[$0.id] == nil }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.untrackedGoals = $0 }
            .store(in: &subscribers)
    }

    func trackGoal(_ goal: Goal) {
        goalService.trackGoal(goal)
            .errorHandled(by: alertService)
    }
}

struct GoalPicker: View {
    @StateObject private var viewModel = GoalPickerViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(viewModel.untrackedGoals) { goal in
                    GoalCard(goal: goal)
                        .onTap { viewModel.trackGoal(goal) }
                        .cardButtonStyle(.modalCard)
                        .disabled(!goal.isTrackable)
                }
            }
        }
    }
}

struct GoalPicker_Previews: PreviewProvider {
    static var previews: some View {
        #if DEBUG
        Resolver.root = .mock
        #endif
        return GoalPicker()
            .preferredColorScheme(.dark)
    }
}
