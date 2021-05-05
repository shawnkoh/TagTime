//
//  GoalPicker.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/5/21.
//

import SwiftUI

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
//                        .background(Color.modalCard)
                        .disabled(!goal.isTrackable)
                }
            }
        }
    }
}

struct GoalPicker_Previews: PreviewProvider {
    static var previews: some View {
        GoalPicker()
    }
}
