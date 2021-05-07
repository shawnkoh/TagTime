//
//  GoalList.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/5/21.
//

import SwiftUI

struct GoalList: View {
    @EnvironmentObject var goalService: GoalService

    var body: some View {
        VStack(alignment: .leading) {
            PageTitle(title: "Goal List", subtitle: "Don't let the bee sting!")

            ForEach(goalService.trackedGoals) { goal in
                Text(goal.slug)
            }
        }
        .environmentObject(goalService)
    }
}

struct GoalList_Previews: PreviewProvider {
    static var previews: some View {
        GoalList()
    }
}
