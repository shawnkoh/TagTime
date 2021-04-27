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
    
    let action: ([Tag]) -> Void

    var filteredTags: [String] {
        let tags = answerService.answers.flatMap { $0.tags }
        let uniqueTags = Array(Set(tags))
        // TODO: Use async search instead to make it not laggy
        let fuse = Fuse()
        let results = fuse.search(search, in: uniqueTags)
        return results.map { uniqueTags[$0.index] }
    }

    var body: some View {
        if search == "", let latestAnswer = answerService.latestAnswer {
            button(text: latestAnswer.tagDescription, action: { action(latestAnswer.tags) })
        } else if search != "" {
            VStack {
                ForEach(filteredTags, id: \.self) { tag in
                    button(text: tag, action: { action([tag]) })
                }
            }
        } else {
            EmptyView()
        }
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
        AnswerSuggester(search: .constant(""), action: { _ in })
            .environmentObject(AnswerService.shared)
    }
}
