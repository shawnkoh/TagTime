//
//  GoalDetail.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/5/21.
//

import SwiftUI

struct GoalDetailConfig {
    var isPresented = false
    var goal: Goal!

    mutating func present(goal: Goal) {
        isPresented = true
        self.goal = goal
    }

    mutating func dismiss() {
        isPresented = false
    }
}

struct GoalDetail: View {
    @EnvironmentObject var goalService: GoalService
    @EnvironmentObject var tagService: TagService
    @Binding var config: GoalDetailConfig
    @State var tagPickerConfig = TagPickerConfig()

    init(config: Binding<GoalDetailConfig>) {
        self._config = config
    }

    var body: some View {
        VStack(alignment: .leading) {
            GoalTitle(goal: config.goal)

            if let tracker = goalService.goalTrackers[config.goal.id] {
                VStack {
                    List {
                        ForEach(tracker.tags, id: \.self) { tag in
                            Text(tag)
                        }
                        .onDelete(perform: delete)
                    }
                    Text("Add Tag")
                        .onTap { tagPickerConfig.present() }
                        .cardButtonStyle(.modalCard)
                        .sheet(isPresented: $tagPickerConfig.isPresented) {
                            TagPicker(config: $tagPickerConfig, goal: config.goal)
                                .environmentObject(self.tagService)
                                .environmentObject(self.goalService)
                        }
                }
            }

            Spacer()

            Text("Stop Tracking")
                .onTap {
                    goalService.untrackGoal(config.goal)
                    config.dismiss()
                }
                .cardButtonStyle(.modalCard)
        }
    }

    private func delete(at offset: IndexSet) {}
}

struct GoalDetail_Previews: PreviewProvider {
    static var previews: some View {
        GoalDetail(config: .constant(.init(isPresented: true, goal: Stub.goal)))
            .environmentObject(GoalService.shared)
            .environmentObject(TagService.shared)
    }
}
