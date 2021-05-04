//
//  GoalList.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/5/21.
//

import SwiftUI

struct GoalList: View {
    @StateObject var beeminderService: BeeminderService

    init(credential: BeeminderCredential) {
        _beeminderService = StateObject(wrappedValue: BeeminderService(credential: credential))
    }

    var body: some View {
        VStack(alignment: .leading) {
            PageTitle(title: "Goal List", subtitle: "Don't let the bee sting!")

            ForEach(beeminderService.goals) { goal in
                Text(goal.slug)
            }
        }
        .environmentObject(beeminderService)
        .onAppear() { beeminderService.getGoals() }
    }
}

struct GoalList_Previews: PreviewProvider {
    static var previews: some View {
        GoalList(credential: .init(username: "shawnkoh", accessToken: "test"))
    }
}
