//
//  TrackedGoalCard.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 9/5/21.
//

import SwiftUI
import Beeminder

struct TrackedGoalCard: View {
    @State private var isDetailPresented = false

    let goal: Goal

    var body: some View {
        GoalCard(goal: goal)
            .onTap { isDetailPresented = true }
            .cardButtonStyle(.baseCard)
            .fullScreenCover(isPresented: $isDetailPresented) {
                GoalDetail(goal: goal, isPresented: $isDetailPresented)
                    .background(Color.modalBackground)
            }
    }
}

struct TrackedGoalCard_Previews: PreviewProvider {
    static var previews: some View {
        TrackedGoalCard(goal: Stub.goal)
    }
}
