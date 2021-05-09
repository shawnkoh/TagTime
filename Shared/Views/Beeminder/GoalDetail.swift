//
//  GoalDetail.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/5/21.
//

import SwiftUI
import Beeminder
import Resolver
import Combine

struct GoalDetailConfig {
    var isPresented = false
    // TODO: Accept Goal in GoalDetail instead
    var goal: Goal!

    mutating func present(goal: Goal) {
        isPresented = true
        self.goal = goal
    }

    mutating func dismiss() {
        isPresented = false
    }
}

final class GoalDetailViewModel: ObservableObject {
    @Injected private var goalService: GoalService
    @Injected private var tagService: TagService
    @Injected private var alertService: AlertService

    func untrackGoal(_ goal: Goal) {
        goalService
            .untrackGoal(goal)
            .errorHandled(by: alertService)
    }
}

struct GoalDetail: View {
    @StateObject private var viewModel = GoalDetailViewModel()
    @Binding var config: GoalDetailConfig
    @State private var isTagPickerPresented = false

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
                        viewModel.untrackGoal(config.goal)
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
        }
    }
}

struct GoalDetail_Previews: PreviewProvider {
    static var previews: some View {
        GoalDetail(config: .constant(.init(isPresented: true, goal: Stub.goal)))
    }
}
