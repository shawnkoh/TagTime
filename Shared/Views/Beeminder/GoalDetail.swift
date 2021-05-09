//
//  GoalDetail.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/5/21.
//

import SwiftUI
import Beeminder
import Resolver

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
    @State private var isTagPickerPresented = false

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
                .onTap { isTagPickerPresented = true }
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
        .sheet(isPresented: $isTagPickerPresented) {
            TagPicker(goal: config.goal)
                .environmentObject(self.tagService)
                .environmentObject(self.goalService)
        }
    }
}

struct GoalDetail_Previews: PreviewProvider {
    @Injected static var goalService: GoalService
    @Injected static var tagService: TagService

    static var previews: some View {
        GoalDetail(config: .constant(.init(isPresented: true, goal: Stub.goal)))
            .environmentObject(goalService)
            .environmentObject(tagService)
    }
}
