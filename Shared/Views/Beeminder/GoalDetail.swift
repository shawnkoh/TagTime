//
//  GoalDetail.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/5/21.
//

import SwiftUI

struct GoalDetailConfig {
    var isPresented = false
    var goal: Goal!

    mutating func present(goal: Goal) {
        isPresented = true
        self.goal = goal
    }

    mutating func dismiss() {
        isPresented = false
    }
}

struct GoalDetail: View {
    @EnvironmentObject var goalService: GoalService
    @EnvironmentObject var tagService: TagService
    @Binding var config: GoalDetailConfig
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var dueInDescription: String
    @State var tagPickerConfig = TagPickerConfig()

    // Initialising with goal is a shitty workaround to init dueInDescription. Otherwise, the
    // interface opens with a blank description.
    // TODO: Find a better way to handle this.
    init(config: Binding<GoalDetailConfig>, goal: Goal) {
        self._config = config
        dueInDescription = goal.dueInDescription(currentTime: Date())
    }

    private var pledge: String {
        guard let pledge = config.goal.pledge else {
            return ""
        }
        return "or pay $\(Int(pledge))"
    }

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text(config.goal.slug)
                    .bold()
                    .font(.title3)
                    .padding([.top, .leading])
                Text("Due in \(dueInDescription) \(pledge)")
                    .foregroundColor(config.goal.color)
                    .padding()
                    .font(.body)
                    .onReceive(timer) { time in
                        dueInDescription = config.goal.dueInDescription(currentTime: time)
                    }
                // TODO: Image
            }

            if let tracker = goalService.goalTrackers[config.goal.id] {
                VStack {
                    List {
                        ForEach(tracker.tags, id: \.self) { tag in
                            Text(tag)
                        }
                        .onDelete(perform: delete)
                    }
                    Text("+")
                        .onTap { tagPickerConfig.present() }
                        .sheet(isPresented: $tagPickerConfig.isPresented) {
                            TagPicker(config: $tagPickerConfig, goal: config.goal)
                                .environmentObject(self.tagService)
                                .environmentObject(self.goalService)
                        }
                }
            }

            Spacer()

            Text("Stop Tracking")
            .onTap {
                goalService.untrackGoal(config.goal)
                config.dismiss()
            }
            .cardButtonStyle(.modalCard)
        }
    }

    private func delete(at offset: IndexSet) {}
}

struct GoalDetail_Previews: PreviewProvider {
    static var previews: some View {
        GoalDetail(config: .constant(.init()), goal: Stub.goal)
            .environmentObject(GoalService.shared)
            .environmentObject(TagService.shared)
    }
}
