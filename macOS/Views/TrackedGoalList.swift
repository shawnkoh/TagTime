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
    @State private var goal: Goal?

    var body: some View {
        NavigationView {
            VStack {
                // Copied implementation of Fruta sample app
                // Somehow this doesn't work if we use ScrollView
                ScrollViewReader { proxy in
                    // Somehow this doesn't work if we use LazyVStack
                    List {
                        PageTitle(title: "Tracked Goals", subtitle: "Don't let the bee sting!")

                        ForEach(viewModel.trackedGoals) { goal in
                            NavigationLink(
                                destination: GoalDetail(goal: goal, isPresented: .constant(true)),
                                tag: goal,
                                selection: $goal
                            ) {
                                GoalCard(goal: goal)
                                    .cardStyle(.baseCard)
                            }
                        }
                    }
                }

                Text("TRACK NEW GOAL")
                    .onTap { isGoalPickerPresented = true }
                    .cardButtonStyle(.modalCard)
                    .sheet(isPresented: $isGoalPickerPresented) {
                        GoalPicker()
                            .frame(minWidth: 400, minHeight: 300)
                            .toolbar {
                                ToolbarItem {
                                    Button(action: { self.isGoalPickerPresented = false }) {
                                        Text("Done")
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            .background(Color.modalBackground)
                    }
            }
            .frame(minWidth: 380)

            Text("Select a goal")
        }
    }
}

struct TrackedGoalList_Previews: PreviewProvider {
    static var previews: some View {
        #if DEBUG
        Resolver.root = .mock
        #endif
        return TrackedGoalList().frame(width: 1000)
    }
}
