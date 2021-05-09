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
    let goal: Goal
    @Binding var isPresented: Bool
    @State private var isTagPickerPresented = false

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text(goal.slug)
                    .bold()
                    .font(.title)
                GoalCountdown(goal: goal)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            .padding(.bottom)

            TagList(goal: goal)

            Spacer()

            Text("Edit Tags")
                .onTap { isTagPickerPresented = true }
                .cardButtonStyle(.modalCard)

            HStack {
                Text("Stop Tracking")
                    .onDoubleTap("Tap again") {
                        viewModel.untrackGoal(goal)
                        isPresented = false
                    }
                    .cardButtonStyle(.modalCard)

                Text("X")
                    .onTap { isPresented = false }
                    .cardButtonStyle(.modalCard)
            }
        }
        .padding()
        .sheet(isPresented: $isTagPickerPresented) {
            TagPicker(goal: goal)
        }
    }
}

struct GoalDetail_Previews: PreviewProvider {
    static var previews: some View {
        GoalDetail(goal: Stub.goal, isPresented: .constant(true))
    }
}
