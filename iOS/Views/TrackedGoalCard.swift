//
//  TrackedGoalCard.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 24/5/21.
//

import SwiftUI
import Beeminder
import Resolver

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

#if DEBUG
struct TrackedGoalCard_Previews: PreviewProvider {
    static let goalService: GoalService = {
        Resolver.root = .mock
        return Resolver.resolve()
    }()

    static var previews: some View {
        TrackedGoalCard(goal: goalService.goals.first!)
    }
}
#endif
