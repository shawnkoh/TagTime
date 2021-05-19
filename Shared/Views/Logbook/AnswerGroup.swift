//
//  AnswerGroup.swift
//  TagTime
//
//  Created by Shawn Koh on 19/5/21.
//

import SwiftUI
import Resolver

final class AnswerGroupViewModel: ObservableObject {
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

struct AnswerGroup: View {
    @StateObject private var viewModel = AnswerGroupViewModel()

    let answers: [Answer]

    @State private var isExpanded = false

    var body: some View {
        if isExpanded {
            GroupBox {
                ForEach(answers, id: \.self) { answer in
                    LogbookCard(answer: answer)
                }
            }
            .onDisappear { isExpanded = false }
        } else {
            VStack {
                Text(answers.first!.tagDescription)
                Text(
                    "\(viewModel.dateFormatter.string(from: answers.last!.ping)) -> \(viewModel.dateFormatter.string(from: answers.first!.ping))"
                )
            }
            .onTap { isExpanded = true }
            .cardButtonStyle(.baseCard)
        }
    }
}

struct AnswerGroup_Previews: PreviewProvider {
    static let answerService: AnswerService = {
        Resolver.root = .mock
        return Resolver.resolve()
    }()

    static var previews: some View {
        AnswerGroup(answers: Array(answerService.answers.values))
    }
}
