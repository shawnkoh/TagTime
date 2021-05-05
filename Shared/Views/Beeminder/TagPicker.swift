//
//  TagPicker.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 5/5/21.
//

import SwiftUI

struct TagPickerConfig {
    var isPresented = false

    mutating func present() {
        isPresented = true
    }

    mutating func dismiss() {
        isPresented = false
    }
}

struct TagPicker: View {
    @EnvironmentObject var tagService: TagService
    @EnvironmentObject var goalService: GoalService
    @Binding var config: TagPickerConfig
    let goal: Goal

    var activeTags: [Tag] {
        tagService.tags
            .filter { $0.value.count > 0 }
            .reduce(into: []) { result, cursor in
                result.append(cursor.key)
            }
    }

    var trackedTags: [Tag] {
        goalService.goalTrackers[goal.id]?.tags ?? []
    }

    var untrackedTags: [Tag] {
        let trackedTags = Set(trackedTags)
        return activeTags.filter { !trackedTags.contains($0) }
    }

    var body: some View {
        VStack {
            List {
                ForEach(untrackedTags, id: \.self) { tag in
                    Text(tag)
                }
                .onDelete(perform: delete)
            }
        }
    }

    private func delete(offsets: IndexSet) {
        let tagsToRemove = offsets.map { trackedTags[$0] }
        goalService.untrackTags(tagsToRemove, for: goal)
    }
}

struct TagPicker_Previews: PreviewProvider {
    static var previews: some View {
        TagPicker(config: .constant(.init()), goal: Stub.goal)
            .environmentObject(TagService.shared)
    }
}
