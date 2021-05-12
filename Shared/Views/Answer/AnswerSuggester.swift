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
    @Injected private var answerService: AnswerService
    @Injected private var tagService: TagService

    @Published private(set) var filteredTags: [Tag] = []
    @Published private(set) var latestAnswer: String?
    @Published var keyword = ""

    private var subscribers = Set<AnyCancellable>()

    init() {
        tagService.activeTagsPublisher
            .combineLatest($keyword)
            // TODO: Ideally we should flatMap here, but fuse doesn't have Combine support so we use a closure callback for now
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activeTags, keyword in
                guard keyword.last != " ", let keyword = keyword.split(separator: " ").last else {
                    self?.filteredTags = []
                    return
                }
                let fuse = Fuse()
                fuse.search(String(keyword), in: activeTags) { results in
                    self?.filteredTags = results
                        // TODO: Not sure about this sorting and suffix
                        .sorted { $0.score > $1.score }
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
    @Binding var keyword: String

    var body: some View {
        if keyword == "", let latestAnswer = viewModel.latestAnswer {
            Text(latestAnswer)
                .onTap { replaceKeyword(with: latestAnswer) }
                .cardButtonStyle(.modalCard)
        } else if keyword != "" {
            VStack {
                ForEach(viewModel.filteredTags, id: \.self) { tag in
                    Text(tag)
                        .onTap { replaceKeyword(with: tag) }
                        .cardButtonStyle(.modalCard)
                }
            }
            .onChange(of: keyword) { keyword in
                viewModel.keyword = keyword
            }
        } else {
            EmptyView()
        }
    }

    private func replaceKeyword(with suggestion: String) {
        var result = keyword.split(separator: " ").dropLast().joined(separator: " ")
        if result.count > 0 {
            result += " \(suggestion) "
        } else {
            result = "\(suggestion) "
        }
        keyword = result
    }
}

struct AnswerSuggester_Previews: PreviewProvider {
    static var previews: some View {
        #if DEBUG
        Resolver.root = .mock
        #endif
        return AnswerSuggester(keyword: .constant(""))
    }
}
