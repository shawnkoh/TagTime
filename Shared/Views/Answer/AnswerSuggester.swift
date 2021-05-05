//
//  AnswerSuggester.swift
//  TagTime
//
//  Created by Shawn Koh on 26/4/21.
//

import SwiftUI
import Fuse

// TODO: This should actually be renamed TagSuggester
struct AnswerSuggester: View {
    @EnvironmentObject var answerService: AnswerService
    @EnvironmentObject var tagService: TagService

    @Binding var keyword: String
    @State private var filteredTags = [String]()
    
    var tags: [Tag] {
        tagService.tags
            .filter { $0.value.count > 0 }
            .reduce(into: []) { result, cursor in
                result.append(cursor.key)
            }
    }

    var body: some View {
        if keyword == "", let latestAnswer = answerService.latestAnswer {
            button(
                text: latestAnswer.tagDescription,
                action: { replaceKeyword(with: latestAnswer.tagDescription) }
            )
        } else if keyword != "" {
            VStack {
                ForEach(filteredTags, id: \.self) { tag in
                    button(text: tag, action: { replaceKeyword(with: tag) })
                }
            }
            .onChange(of: keyword) { search in
                guard let keyword = search.split(separator: " ").last else {
                    filteredTags = []
                    return
                }
                let fuse = Fuse()
                fuse.search(String(keyword), in: tags) { results in
                    filteredTags = results.map { tags[$0.index] }
                }
            }
        } else {
            EmptyView()
        }
    }

    private func replaceKeyword(with suggestion: String) {
        var result = keyword.split(separator: " ").dropLast().joined(separator: " ")
        result += " \(suggestion)"
        keyword = result
    }

    @ViewBuilder
    private func button(text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(text)
                    .foregroundColor(.primary)
                    .padding()
                Spacer()
            }
            .background(Color.hsb(223, 69, 90))
            .cornerRadius(8)
        }
    }
}

struct AnswerSuggester_Previews: PreviewProvider {
    static var previews: some View {
        AnswerSuggester(keyword: .constant(""))
            .environmentObject(AnswerService.shared)
    }
}
