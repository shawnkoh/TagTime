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
    @State private var filteredTags = [String]()

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
            .onChange(of: search) { search in
                guard let keyword = search.split(separator: " ").last else {
                    filteredTags = []
                    return
                }
                let tags = answerService.answers.flatMap { $0.tags }
                let uniqueTags = Array(Set(tags))
                let fuse = Fuse()
                fuse.search(String(keyword), in: uniqueTags) { results in
                    filteredTags = results.map { uniqueTags[$0.index] }
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
