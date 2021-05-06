//
//  GoalCard.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 5/5/21.
//

import SwiftUI
import Beeminder

struct GoalCard: View {
    let goal: Goal

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(goal.slug)
                    .bold()
                GoalCountdown(goal: goal)
            }
            Spacer()
        }
    }
}

struct GoalCard_Previews: PreviewProvider {
    static var previews: some View {
        GoalCard(goal: Stub.goal)
    }
}
