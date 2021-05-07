//
//  TagList.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 5/5/21.
//

import SwiftUI
import Beeminder

struct TagList: View {
    @EnvironmentObject var tagService: TagService
    @EnvironmentObject var goalService: GoalService
    let goal: Goal

    var activeTags: [Tag] {
        tagService.tags
            .filter { $0.value.count > 0 }
            .reduce(into: []) { result, cursor in
                result.append(cursor.key)
            }
            .sorted()
    }

    var trackedTags: [Tag] {
        goalService.goalTrackers[goal.id]?.tags.sorted() ?? []
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(trackedTags, id: \.self) { tag in
                    Text(tag)
                        .onTap {}
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
