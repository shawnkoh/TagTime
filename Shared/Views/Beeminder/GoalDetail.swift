//
//  GoalDetail.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/5/21.
//

import SwiftUI
import Beeminder
import Resolver
import Combine

final class GoalDetailViewModel: ObservableObject {
    @LazyInjected private var goalService: GoalService
    @LazyInjected private var tagService: TagService
    @LazyInjected private var alertService: AlertService

    func untrackGoal(_ goal: Goal) {
        goalService
            .untrackGoal(goal)
            .errorHandled(by: alertService)
    }
}

struct GoalDetail: View {
    @StateObject private var viewModel = GoalDetailViewModel()
    let goal: Goal
    @Binding var isPresented: Bool
    @State private var isTagPickerPresented = false

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text(goal.slug)
                    .bold()
                    .font(.title)
                GoalCountdown(goal: goal)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            .padding(.bottom)

            TagList(goal: goal)

            Spacer()

            Text("Edit Tags")
                .onTap { isTagPickerPresented = true }
                .cardButtonStyle(.modalCard)

            HStack {
                Text("Stop Tracking")
                    .onDoubleTap("Tap again") {
                        viewModel.untrackGoal(goal)
                        isPresented = false
                    }
                    .cardButtonStyle(.modalCard)

                #if os(iOS)
                Text("X")
                    .onTap { isPresented = false }
                    .cardButtonStyle(.modalCard)
                #endif
            }
        }
        .padding()
        .modify {
            #if os(macOS)
                $0
                    .sheet(isPresented: $isTagPickerPresented) {
                        TagPicker(goal: goal)
                            .frame(minWidth: 400, minHeight: 300)
                            .toolbar {
                                ToolbarItem {
                                    Button(action: { self.isTagPickerPresented = false }) {
                                        Text("Done")
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                    }
            #else
                $0
            #endif
        }
    }
}

#if DEBUG
struct GoalDetail_Previews: PreviewProvider {
    static let service: GoalService = {
        Resolver.root = .mock
        return Resolver.resolve()
    }()

    static var previews: some View {
        GoalDetail(goal: service.goals.first!, isPresented: .constant(true))
    }
}
#endif
