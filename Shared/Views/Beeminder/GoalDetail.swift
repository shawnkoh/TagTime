//
//  GoalDetail.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/5/21.
//

import SwiftUI

struct GoalDetail: View {
    @EnvironmentObject var goalService: GoalService
    let goal: Goal
    @Binding var isPresented: Bool
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var dueInDescription: String

    init(goal: Goal, isPresented: Binding<Bool>) {
        self.goal = goal
        self._isPresented = isPresented
        dueInDescription = goal.dueInDescription(currentTime: Date())
    }

    private var pledge: String {
        guard let pledge = goal.pledge else {
            return ""
        }
        return "or pay $\(Int(pledge))"
    }

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text(goal.slug)
                    .bold()
                    .font(.title3)
                    .padding([.top, .leading])
                Text("Due in \(dueInDescription) \(pledge)")
                    .foregroundColor(goal.color)
                    .padding()
                    .font(.body)
                    .onReceive(timer) { time in
                        dueInDescription = goal.dueInDescription(currentTime: time)
                    }
                // TODO: Image
            }
            Spacer()
            HStack {
                Spacer()
                Text("Delete")
                    .foregroundColor(.red)
                Spacer()
            }
            .onPress {
                goalService.untrackGoal(goal)
                isPresented = false
            }
        }
        .foregroundColor(.white)
        .background(Color.hsb(213, 24, 18))
    }
}

struct GoalDetail_Previews: PreviewProvider {
    static var previews: some View {
        GoalDetail(goal: Stub.goal, isPresented: .constant(true))
            .environmentObject(GoalService.shared)
    }
}
