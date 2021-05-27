//
//  TrackedGoalList.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/5/21.
//

import SwiftUI
import Resolver
import Beeminder
import SwiftUIX

struct TrackedGoalList: View {
    @StateObject private var viewModel = TrackedGoalListViewModel()
    @State private var isGoalPickerPresented = false

    var body: some View {
        VStack(alignment: .leading) {
            PageTitle(title: "Tracked Goals", subtitle: "Don't let the bee sting!")

            // TODO: This doesn't render if we have `if viewModel.trackedGoals.count > 0`
            // It renders if we use a ScrollView, which indicates a possible bug with CocoaScrollView.
            // But for now since we don't have placeholders I decided to use
            // a CocoaScrollView to keep things simple
            // I tested and confirmed that the viewModel.trackedGoals is updating correctly
            // and that SwiftUI triggers onChange(of: viewModel.trackedGoals)
            // I also confirmed that SwiftUI renders a text update correctly with
            // Text(viewModel.trackedGoals.count)
            // So the problem is most likely CocoaScrollView.
            CocoaScrollView {
                LazyVStack(alignment: .center, spacing: 2, pinnedViews: []) {
                    ForEach(viewModel.trackedGoals) { goal in
                        TrackedGoalCard(goal: goal)
                    }
                }
            }
            .onRefresh(viewModel.refreshGoals)
            .isRefreshing(viewModel.isRefreshing)

            Text("TRACK NEW GOAL")
                .onTap { isGoalPickerPresented = true }
                .cardButtonStyle(.modalCard)
                .sheet(isPresented: $isGoalPickerPresented) {
                    GoalPicker()
                        .background(Color.modalBackground)
                }
        }
    }
}

#if DEBUG
struct TrackedGoalList_Previews: PreviewProvider {
    static var previews: some View {
        Resolver.root = .mock
        return TrackedGoalList()
    }
}
#endif
