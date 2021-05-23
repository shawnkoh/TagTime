//
//  AnswerSuggester.swift
//  TagTime
//
//  Created by Shawn Koh on 26/4/21.
//

import SwiftUI
import Fuse
import Resolver
import Combine

final class AnswerSuggesterViewModel: ObservableObject {
    @LazyInjected private var answerService: AnswerService
    @LazyInjected private var tagService: TagService

    @Published private(set) var filteredTags: [Tag] = []
    @Published private(set) var latestAnswer: String?
    @Published var input = ""

    private var subscribers = Set<AnyCancellable>()

    init() {
        tagService.activeTagsPublisher
            .combineLatest($input)
            // TODO: Ideally we should flatMap here, but fuse doesn't have Combine support so we use a closure callback for now
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activeTags, input in
                guard input.last != " ", let keyword = input.split(separator: " ").last else {
                    self?.filteredTags = []
                    return
                }
                let fuse = Fuse()
                fuse.search(String(keyword), in: activeTags) { results in
                    self?.filteredTags = results
                        .filter { result in
                            let activeTag = activeTags[result.index]
                            return !input.contains(activeTag)
                        }
                        // TODO: Not sure about this sorting and suffix
                        .sorted { $0.score < $1.score }
                        .suffix(7)
                        .map { activeTags[$0.index] }
                }
            }
            .store(in: &subscribers)

        answerService
            .latestAnswerPublisher
            .receive(on: DispatchQueue.main)
            .sink { self.latestAnswer = $0?.tagDescription }
            .store(in: &subscribers)
    }
}

// TODO: This should actually be renamed TagSuggester
struct AnswerSuggester: View {
    @StateObject var viewModel = AnswerSuggesterViewModel()
    @Binding var input: String

    var body: some View {
        if input == "", let latestAnswer = viewModel.latestAnswer {
            Text(latestAnswer)
                .onTap { replaceKeyword(with: latestAnswer) }
                .cardButtonStyle(.modalCard)
        } else if input != "" {
            VStack {
                ForEach(viewModel.filteredTags, id: \.self) { tag in
                    Text(tag)
                        .onTap { replaceKeyword(with: tag) }
                        .cardButtonStyle(.modalCard)
                }
            }
            .onChange(of: input) { input in
                viewModel.input = input
            }
        } else {
            EmptyView()
        }
    }

    private func replaceKeyword(with suggestion: String) {
        var result = input.split(separator: " ").dropLast().joined(separator: " ")
        if result.count > 0 {
            result += " \(suggestion) "
        } else {
            result = "\(suggestion) "
        }
        input = result
    }
}

struct AnswerSuggester_Previews: PreviewProvider {
    static var previews: some View {
        #if DEBUG
        Resolver.root = .mock
        #endif
        return AnswerSuggester(input: .constant(""))
    }
}
