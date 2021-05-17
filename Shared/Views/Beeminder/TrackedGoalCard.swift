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
            // TODO: NavigationLink
            .popover(isPresented: $isDetailPresented, arrowEdge: .trailing) {
                GoalDetail(goal: goal, isPresented: $isDetailPresented)
                    .background(Color.modalBackground)
                    .fixedSize()
            }
        #endif
    }
}

struct TrackedGoalCard_Previews: PreviewProvider {
    static let goalService: GoalService = {
        Resolver.root = .mock
        return Resolver.resolve()
    }()

    static var previews: some View {
        TrackedGoalCard(goal: goalService.goals.first!)
    }
}
