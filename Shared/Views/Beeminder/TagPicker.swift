//
//  TagPicker.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 5/5/21.
//

import SwiftUI
import Beeminder
import Resolver
import Combine

final class TagPickerViewModel: ObservableObject {
    @Injected private var tagService: TagService
    @Injected private var goalService: GoalService
    @Injected private var alertService: AlertService

    @Published private(set) var goalTrackers: [String: GoalTracker] = [:]
    @Published private(set) var activeTags: [Tag] = []

    private var subscribers = Set<AnyCancellable>()

    init() {
        goalService.$goalTrackers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.goalTrackers = $0 }
            .store(in: &subscribers)

        tagService.$tags
            .flatMap { Publishers.Sequence(sequence: $0) }
            .filter { $0.value.count > 0 }
            .map { $0.key }
            .collect()
            .map { $0.sorted() }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.activeTags = $0 }
            .store(in: &subscribers)
    }

    func trackTags(_ tags: [Tag], for goal: Goal) {
        goalService
            .trackTags(tags, for: goal)
            .errorHandled(by: alertService)
    }
}

struct TagPicker: View {
    @StateObject private var viewModel = TagPickerViewModel()
    let goal: Goal

    @State private var customTags = ""

    // TODO: This should only save upon clicking save, not upon each button.

    var trackedTags: [Tag] {
        viewModel.goalTrackers[goal.id]?.tags.sorted() ?? []
    }

    // This is required because of the ability to track tags that does not exist yet
    // that have been created through the text field.
    var selectableTags: [Tag] {
        var selectableTags = Set(viewModel.activeTags)
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
                    viewModel.trackTags(newTags, for: goal)
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
                                viewModel.trackTags(newTags, for: goal)
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
        TagPicker(goal: Stub.goal)
    }
}
