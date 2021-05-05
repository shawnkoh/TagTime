//
//  TrackedGoalList.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/5/21.
//

import SwiftUI

struct TrackedGoalList: View {
    @EnvironmentObject var goalService: GoalService
    @EnvironmentObject var tagService: TagService
    @State var pickerConfig = GoalPickerConfig()
    @State var detailConfig = GoalDetailConfig()

    var body: some View {
        VStack(alignment: .leading) {
            PageTitle(title: "Tracked Goals", subtitle: "Don't let the bee sting!")

            if goalService.trackedGoals.count > 0 {
                ScrollView {
                    LazyVStack(alignment: .center, spacing: 2, pinnedViews: []) {
                        ForEach(goalService.trackedGoals) { goal in
                            GoalCard(goal: goal)
                                .onTap { detailConfig.present(goal: goal) }
                                .cardButtonStyle(.baseCard)
                                .fullScreenCover(isPresented: $detailConfig.isPresented) {
                                    GoalDetail(config: $detailConfig)
                                        .background(Color.modalBackground)
                                        .environmentObject(self.goalService)
                                        .environmentObject(self.tagService)
                                }
                        }
                    }
                }
            } else {
                Spacer()
                // TODO: Add some placeholder here. Refer to Bear / Actions / Spark
            }

            Text("TRACK NEW GOAL")
                .onTap { pickerConfig.present() }
                .cardButtonStyle(.modalCard)
                .sheet(isPresented: $pickerConfig.isPresented) {
                    GoalPicker()
                        .environmentObject(self.goalService)
                        .environmentObject(self.tagService)
                        .background(Color.sheetBackground)
                }
        }
    }
}

struct TrackedGoalList_Previews: PreviewProvider {
    static var previews: some View {
        TrackedGoalList()
            .environmentObject(GoalService.shared)
            .environmentObject(TagService.shared)
    }
}
