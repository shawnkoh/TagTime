//
//  BatchAnswerCreator.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 26/4/21.
//

import SwiftUI

struct BatchAnswerConfig {
    var isPresented = false
    var response = ""

    var tags: [Tag] {
        response.split(separator: " ").map { Tag($0) }
    }

    mutating func show() {
        response = ""
        isPresented = true
    }

    mutating func dismiss() {
        isPresented = false
    }
}

struct BatchAnswerCreator: View {
    @EnvironmentObject var answerService: AnswerService
    @Binding var config: BatchAnswerConfig

    var body: some View {
        VStack(alignment: .leading) {
            Text("What were you doing from")
            Text("")
            TextField(
                "PING1 PING2",
                text: $config.response,
                onCommit: { answerAllUnansweredPings(tags: config.tags) }
            )

            Spacer()

            AnswerSuggester(action: answerAllUnansweredPings(tags:))
        }
    }

    private func answerAllUnansweredPings(tags: [Tag]) {
        guard tags.count > 0 else {
            return
        }
        let answers = answerService.unansweredPings.map { Answer(ping: $0, tags: tags) }
        answerService.batchAnswers(answers)
        config.dismiss()
    }
}

struct BatchAnswerCreator_Previews: PreviewProvider {
    static var previews: some View {
        BatchAnswerCreator(config: .constant(.init()))
            .environmentObject(AnswerService.shared)
    }
}
