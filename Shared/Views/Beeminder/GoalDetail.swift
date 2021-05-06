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
            VStack(alignment: .leading) {
                Text(config.goal.slug)
                    .bold()
                    .font(.title)
                GoalCountdown(goal: config.goal)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            .padding(.bottom)

            TagList(goal: config.goal)

            Spacer()

            Text("Edit Tags")
                .onTap { tagPickerConfig.present() }
                .cardButtonStyle(.modalCard)

            HStack {
                Text("Stop Tracking")
                    .onDoubleTap("Tap again") {
                        goalService.untrackGoal(config.goal)
                        config.dismiss()
                    }
                    .cardButtonStyle(.modalCard)

                Text("X")
                    .onTap { config.dismiss() }
                    .cardButtonStyle(.modalCard)
            }
        }
        .padding()
        .sheet(isPresented: $tagPickerConfig.isPresented) {
            TagPicker(config: $tagPickerConfig, goal: config.goal)
                .environmentObject(self.tagService)
                .environmentObject(self.goalService)
        }
    }
}

struct GoalDetail_Previews: PreviewProvider {
    static var previews: some View {
        GoalDetail(config: .constant(.init(isPresented: true, goal: Stub.goal)))
            .environmentObject(GoalService.shared)
            .environmentObject(TagService.shared)
    }
}
