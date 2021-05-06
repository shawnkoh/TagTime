//
//  TagPicker.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 5/5/21.
//

import SwiftUI
import Beeminder

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

    @State private var customTags = ""

    // TODO: This should only save upon clicking save, not upon each button.
    // TODO: There should be a way for a user to manually add a tag.

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

    // This is required because of the ability to track tags that does not exist yet
    // that have been created through the text field.
    var selectableTags: [Tag] {
        var selectableTags = Set(activeTags)
        trackedTags.forEach { selectableTags.insert($0) }
        return Array(selectableTags).sorted()
    }

    // TODO: This should be something like AnswerSuggester

    var body: some View {
        VStack {
            ScrollView {
                TextField("sleeping", text: $customTags, onCommit: {
                    guard customTags.count > 0 else {
                        return
                    }
                    let newTags = trackedTags + customTags.split(separator: " ").map { Tag($0) }
                    goalService.trackTags(newTags, for: goal)
                        .errorHandled(by: AlertService.shared)
                    customTags = ""
                })
                .multilineTextAlignment(.center)
                .textFieldStyle(RoundedBorderTextFieldStyle())

                LazyVStack {
                    let trackedTagSet = Set(trackedTags)
                    ForEach(selectableTags, id: \.self) { tag in
                        let isTracked = trackedTagSet.contains(tag)
                        Text(tag)
                            .foregroundColor(isTracked ? .black : .white)
                            .onTap {
                                var newTags = trackedTags
                                if isTracked {
                                    guard let index = newTags.firstIndex(of: tag) else {
                                        return
                                    }
                                    newTags.remove(at: index)
                                } else {
                                    newTags.append(tag)
                                }
                                goalService
                                    .trackTags(newTags, for: goal)
                                    .errorHandled(by: AlertService.shared)
                            }
                            .cardButtonStyle(isTracked ? .white : .black)
                    }
                }
            }
        }
    }
}

struct TagPicker_Previews: PreviewProvider {
    static var previews: some View {
        TagPicker(config: .constant(.init()), goal: Stub.goal)
            .environmentObject(TagService.shared)
    }
}
