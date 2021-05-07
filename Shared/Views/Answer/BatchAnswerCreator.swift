//
//  BatchAnswerCreator.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 26/4/21.
//

import SwiftUI
import SwiftUIX

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
    @EnvironmentObject var pingService: PingService
    @Binding var config: BatchAnswerConfig

    var body: some View {
        VStack(alignment: .leading) {
            Text("What were you doing from")
            Text("")
            CocoaTextField(
                "PING1 PING2",
                text: $config.response,
                onCommit: { answerAllUnansweredPings(tags: config.tags) }
            )
            .isInitialFirstResponder(true)

            Spacer()

            AnswerSuggester(keyword: $config.response)
        }
    }

    private func answerAllUnansweredPings(tags: [Tag]) {
        guard tags.count > 0 else {
            return
        }
        DispatchQueue.global(qos: .utility).async {
            answerService
                .batchAnswerPings(pingDates: pingService.unansweredPings, tags: tags)
                .errorHandled(by: AlertService.shared)
        }
        config.dismiss()
    }
}

struct BatchAnswerCreator_Previews: PreviewProvider {
    static var previews: some View {
        BatchAnswerCreator(config: .constant(.init()))
    }
}
