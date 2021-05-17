//
//  TrackedGoalList.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/5/21.
//

import SwiftUI
import Resolver
import Beeminder

struct TrackedGoalList: View {
    @StateObject private var viewModel = TrackedGoalListViewModel()
    @State private var isGoalPickerPresented = false

    var body: some View {
        VStack(alignment: .leading) {
            PageTitle(title: "Tracked Goals", subtitle: "Don't let the bee sting!")

            if viewModel.trackedGoals.count > 0 {
                ScrollView {
                    LazyVStack(alignment: .center, spacing: 2, pinnedViews: []) {
                        ForEach(viewModel.trackedGoals) { goal in
                            TrackedGoalCard(goal: goal)
                        }
                    }
                }
            } else {
                Spacer()
                // TODO: Add some placeholder here. Refer to Bear / Actions / Spark
            }

            Text("TRACK NEW GOAL")
                .onTap { isGoalPickerPresented = true }
                .cardButtonStyle(.modalCard)
                .fullScreenCover(isPresented: $isGoalPickerPresented) {
                    GoalPicker()
                        .background(Color.sheetBackground)
                }
        }
    }
}

struct TrackedGoalList_Previews: PreviewProvider {
    static var previews: some View {
        #if DEBUG
        Resolver.root = .mock
        #endif
        return TrackedGoalList()
    }
}
