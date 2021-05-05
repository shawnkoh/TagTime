//
//  GoalCard.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/5/21.
//

import SwiftUI

// TODO: This needs a better name. Maybe just GoalTitle?
struct GoalCard: View {
    let goal: Goal
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var dueInDescription: String

    init(goal: Goal) {
        self.goal = goal
        dueInDescription = goal.dueInDescription(currentTime: Date())
    }

    private var pledge: String {
        guard let pledge = goal.pledge else {
            return ""
        }
        return "or pay $\(Int(pledge))"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(goal.slug)
                    .bold()
                    .font(.title3)
                    .padding([.top, .leading])
                Text("Due in \(dueInDescription) \(pledge)")
                    .foregroundColor(goal.color)
                    .padding()
                    .font(.body)
                // TODO: Image
            }
            .foregroundColor(.white)
            Spacer()
        }
        .onReceive(timer) { time in
            dueInDescription = goal.dueInDescription(currentTime: time)
        }
    }
}

struct GoalCard_Previews: PreviewProvider {
    static var previews: some View {
        GoalCard(goal: Stub.goal)
    }
}
