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
    @State var isDetailPresented = false

    var body: some View {
        VStack(alignment: .leading) {
            PageTitle(title: "Tracked Goals", subtitle: "Don't let the bee sting!")

            if goalService.trackedGoals.count > 0 {
                ScrollView {
                    LazyVStack(alignment: .center, spacing: 2, pinnedViews: []) {
                        ForEach(goalService.trackedGoals) { goal in
                            GoalCard(goal: goal)
                                .onPress { isDetailPresented = true }
                                .sheet(isPresented: $isDetailPresented) {
                                    GoalDetail(goal: goal, isPresented: $isDetailPresented)
                                        .environmentObject(self.goalService)
                                }
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
    }
}

struct TrackedGoalList_Previews: PreviewProvider {
    static var previews: some View {
        GoalList()
            .environmentObject(GoalService.shared)
    }
}
