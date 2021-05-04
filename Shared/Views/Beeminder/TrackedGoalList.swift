//
//  TrackedGoalList.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/5/21.
//

import SwiftUI

struct TrackedGoalList: View {
    @EnvironmentObject var goalService: GoalService
    @State var pickerConfig = GoalPickerConfig()

    var body: some View {
        VStack(alignment: .leading) {
            PageTitle(title: "Tracked Goals", subtitle: "Don't let the bee sting!")
                .environmentObject(goalService)

            if goalService.trackedGoals.count > 0 {
                ScrollView {
                    LazyVStack(alignment: .center, spacing: 2, pinnedViews: []) {
                        ForEach(goalService.trackedGoals) { goal in
                            TrackedGoalCard(goal: goal)
                        }
                    }
                }
            } else {
                Spacer()
                // TODO: Add some placeholder here. Refer to Bear / Actions / Spark
            }

            Button(action: { pickerConfig.present() }) {
                HStack {
                    Spacer()
                    Text("TRACK NEW GOAL")
                    Spacer()
                }
            }
            .sheet(isPresented: $pickerConfig.isPresented) {
                GoalPicker()
                    .environmentObject(self.goalService)
            }
        }
        .onAppear() { goalService.getGoals() }
    }
}

struct TrackedGoalList_Previews: PreviewProvider {
    static var previews: some View {
        GoalList()
            .environmentObject(GoalService.shared)
    }
}
