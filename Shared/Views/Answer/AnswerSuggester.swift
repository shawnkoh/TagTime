//
//  AnswerSuggester.swift
//  TagTime
//
//  Created by Shawn Koh on 26/4/21.
//

import SwiftUI
import Fuse

struct AnswerSuggester: View {
    @EnvironmentObject var answerService: AnswerService

    @Binding var search: String

    var filteredTags: [String] {
        let tags = answerService.answers.flatMap { $0.tags }
        let uniqueTags = Array(Set(tags))
        // TODO: Use async search instead to make it not laggy
        guard let keyword = search.split(separator: " ").last else {
            return []
        }
        let fuse = Fuse()
        let results = fuse.search(String(keyword), in: uniqueTags)
        return results.map { uniqueTags[$0.index] }
    }

    var body: some View {
        if search == "", let latestAnswer = answerService.latestAnswer {
            button(
                text: latestAnswer.tagDescription,
                action: { replaceKeyword(with: latestAnswer.tagDescription) }
            )
        } else if search != "" {
            VStack {
                ForEach(filteredTags, id: \.self) { tag in
                    button(text: tag, action: { replaceKeyword(with: tag) })
                }
            }
        } else {
            EmptyView()
        }
    }

    private func replaceKeyword(with suggestion: String) {
        var result = search.split(separator: " ").dropLast().joined(separator: " ")
        result += " \(suggestion)"
        search = result
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
        AnswerSuggester(search: .constant(""))
            .environmentObject(AnswerService.shared)
    }
}
