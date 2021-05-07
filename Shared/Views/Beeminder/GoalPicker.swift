//
//  GoalPicker.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/5/21.
//

import SwiftUI
import Resolver

struct GoalPickerConfig {
    var isPresented = false

    mutating func present() {
        isPresented = true
    }

    mutating func dismiss() {
        isPresented = false
    }
}

struct GoalPicker: View {
    @EnvironmentObject var goalService: GoalService

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(goalService.untrackedGoals) { goal in
                    GoalCard(goal: goal)
                        .onTap { goalService.trackGoal(goal) }
                        .cardButtonStyle(.modalCard)
                        .disabled(!goal.isTrackable)
                }
            }
        }
    }
}

struct GoalPicker_Previews: PreviewProvider {
    @Injected static var goalService: GoalService

    static var previews: some View {
        GoalPicker()
            .environmentObject(goalService)
    }
}
