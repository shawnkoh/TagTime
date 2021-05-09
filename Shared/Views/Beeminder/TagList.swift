//
//  TagList.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 5/5/21.
//

import SwiftUI
import Beeminder
import Resolver
import Combine

final class TagListViewModel: ObservableObject {
    @Injected private var goalService: GoalService

    @Published private(set) var goalTrackers: [String: GoalTracker] = [:]

    private var subscribers = Set<AnyCancellable>()

    init() {
        goalService.$goalTrackers
            .receive(on: DispatchQueue.main)
            .sink { self.goalTrackers = $0 }
            .store(in: &subscribers)
    }
}

struct TagList: View {
    @StateObject private var viewModel = TagListViewModel()
    let goal: Goal

    var trackedTags: [Tag] {
        viewModel.goalTrackers[goal.id]?.tags.sorted() ?? []
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(trackedTags, id: \.self) { tag in
                    Text(tag)
                        .cardStyle(.modalCard)
                }
            }
        }
    }
}

struct TagList_Previews: PreviewProvider {
    static var previews: some View {
        TagList(goal: Stub.goal)
    }
}
