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
    @LazyInjected private var answerablePingService: AnswerablePingService
    @LazyInjected private var alertService: AlertService
    @LazyInjected private var answerBuilderExecutor: AnswerBuilderExecutor

    func answerAllUnansweredPings(response: String) {
        let tags = response.split(separator: " ").map { Tag($0) }
        guard tags.count > 0 else {
            return
        }
        DispatchQueue.global(qos: .utility).async { [self] in
            var builder = AnswerBuilder()
            // TODO: This might be wrong. AnswerBuilder might not be mutated? not sure.
            // TODO: Find out if builders should be structs
            answerablePingService.unansweredPings
                .map { Answer(ping: $0, tags: tags) }
                .forEach { _ = builder.createAnswer($0) }
            builder
                .execute(with: answerBuilderExecutor)
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
            #if os(iOS)
            CocoaTextField(
                "PING1 PING2",
                text: $response,
                onCommit: {
                    viewModel.answerAllUnansweredPings(response: response)
                    isPresented = false
                }
            )
            .isInitialFirstResponder(true)
            #else
            TextField(
                "PING1 PING2",
                text: $response,
                onCommit: {
                    viewModel.answerAllUnansweredPings(response: response)
                    isPresented = false
                }
            )
            .textCase(.lowercase)
            .multilineTextAlignment(.center)
            .background(Color.hsb(207, 26, 14))
            .foregroundColor(.white)
            .cornerRadius(8)
            #endif

            Spacer()

            AnswerSuggester(input: $response)
        }
        .modify {
            #if os(macOS)
            $0.frame(minWidth: 300, minHeight: 400)
            #else
            $0
            #endif
        }
    }
}

#if DEBUG
struct BatchAnswerCreator_Previews: PreviewProvider {
    static var previews: some View {
        Resolver.root = .mock
        return BatchAnswerCreator(isPresented: .constant(true))
    }
}
#endif
