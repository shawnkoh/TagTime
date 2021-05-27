//
//  GoalCountdown.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/5/21.
//

import SwiftUI
import Beeminder
import Resolver

struct GoalCountdown: View {
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
        Text("\(goal.goalType == .drinker ? "limit " : "")\(goal.baremin) \(goal.gunits) due in \(dueInDescription) \(pledge)")
            .foregroundColor(goal.color)
            .onReceive(timer) { time in
                dueInDescription = goal.dueInDescription(currentTime: time)
            }
    }
}

#if DEBUG
struct GoalCountdown_Previews: PreviewProvider {
    static let goalService: GoalService = {
        Resolver.root = .mock
        return Resolver.resolve()
    }()

    static var previews: some View {
        GoalCountdown(goal: goalService.goals.first!)
    }
}
#endif
