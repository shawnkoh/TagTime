//
//  GoalList.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/5/21.
//

import SwiftUI

struct GoalList: View {
    @EnvironmentObject var beeminderService: BeeminderService

    var body: some View {
        VStack(alignment: .leading) {
            PageTitle(title: "Goal List", subtitle: "Don't let the bee sting!")

            ForEach(beeminderService.goals) { goal in
                Text(goal.slug)
            }
        }
        .onAppear() {
            beeminderService.getGoals(with: beeminderService.credential!)
        }
    }
}

struct GoalList_Previews: PreviewProvider {
    static var previews: some View {
        GoalList()
            .environmentObject(BeeminderService.shared)
    }
}
