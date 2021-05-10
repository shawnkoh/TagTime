//
//  BatchAnswerCreator.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 26/4/21.
//

import SwiftUI
import SwiftUIX
import Resolver

final class BatchAnswerCreatorViewModel: ObservableObject {
    @Injected private var answerService: AnswerService
    @Injected private var pingService: PingService
    @Injected private var alertService: AlertService

    func answerAllUnansweredPings(response: String) {
        let tags = response.split(separator: " ").map { Tag($0) }
        guard tags.count > 0 else {
            return
        }
        DispatchQueue.global(qos: .utility).async { [self] in
            let builder = AnswerBuilder()
            pingService.unansweredPings
                .map { Answer(ping: $0, tags: tags) }
                .forEach { _ = builder.createAnswer($0) }
            builder
                .execute()
                .errorHandled(by: alertService)
        }
    }
}

struct BatchAnswerCreator: View {
    @StateObject var viewModel = BatchAnswerCreatorViewModel()
    @State private var response = ""
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text("What were you doing from")
            Text("")
            CocoaTextField(
                "PING1 PING2",
                text: $response,
                onCommit: {
                    viewModel.answerAllUnansweredPings(response: response)
                    isPresented = false
                }
            )
            .isInitialFirstResponder(true)

            Spacer()

            AnswerSuggester(keyword: $response)
        }
    }
}

struct BatchAnswerCreator_Previews: PreviewProvider {
    static var previews: some View {
        BatchAnswerCreator(isPresented: .constant(true))
    }
}
