//
//  TrackedGoalCard.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 9/5/21.
//

import SwiftUI
import Beeminder
import Resolver

struct TrackedGoalCard: View {
    @State private var isDetailPresented = false

    let goal: Goal

    var body: some View {
        #if os(iOS)
        GoalCard(goal: goal)
            .onTap { isDetailPresented = true }
            .cardButtonStyle(.baseCard)
            .fullScreenCover(isPresented: $isDetailPresented) {
                GoalDetail(goal: goal, isPresented: $isDetailPresented)
                    .background(Color.modalBackground)
            }
        #else
        GoalCard(goal: goal)
            .onTap { isDetailPresented = true }
            .cardButtonStyle(.baseCard)
            .sheet(isPresented: $isDetailPresented) {
                GoalDetail(goal: goal, isPresented: $isDetailPresented)
                    .background(Color.modalBackground)
            }
        #endif
    }
}

struct TrackedGoalCard_Previews: PreviewProvider {
    static var previews: some View {
        Resolver.root = .mock
        return TrackedGoalCard(goal: Stub.goal)
    }
}
