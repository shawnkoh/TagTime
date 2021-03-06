//
//  AnswerCreator.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 24/4/21.
//

import SwiftUI
import SwiftUIX
import Resolver

struct AnswerCreatorConfig {
    var isPresented = false
    var pingDate = Date()
    var response = ""
    var editingAnswer: Answer? = nil

    var tags: [String] {
        response.split(separator: " ").map { Tag($0) }
    }
    
    mutating func create(pingDate: Date) {
        isPresented = true
        self.pingDate = pingDate
        self.response = ""
        self.editingAnswer = nil
    }
    
    mutating func edit(answer: Answer) {
        isPresented = true
        self.pingDate = answer.ping
        self.response = answer.tagDescription
        self.editingAnswer = answer
    }

    mutating func dismiss() {
        isPresented = false
        // It's not really necessary to set these because the modal will
        // only get presented when the user calls one of the mutating functions
        // but this is just defensive coding i guess
        self.pingDate = Date()
        self.response = ""
        self.editingAnswer = nil
    }
}

final class AnswerCreatorViewModel: ObservableObject {
    @LazyInjected private var alertService: AlertService
    @LazyInjected private var answerBuilderExecutor: AnswerBuilderExecutor

    private(set) lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    func updateAnswer(_ answer: Answer, tags: [Tag]) {
        var builder = AnswerBuilder()
        builder
            .updateAnswer(answer, tags: tags)
            .execute(with: answerBuilderExecutor)
            .errorHandled(by: alertService)
    }

    func createAnswer(_ answer: Answer) {
        var builder = AnswerBuilder()
        builder
            .createAnswer(answer)
            .execute(with: answerBuilderExecutor)
            .errorHandled(by: alertService)
    }
}

struct AnswerCreator: View {
    @StateObject private var viewModel = AnswerCreatorViewModel()
    @Binding var config: AnswerCreatorConfig

    var body: some View {
        VStack {
            VStack {
                Text("What are you doing")
                    .font(.title2)
                Text("RIGHT NOW?")
                    .font(.title2)
            }
            .padding(.top)

            Text(viewModel.dateFormatter.string(from: config.pingDate))
                .font(.title2)
                .padding([.leading, .trailing, .top])

            #if os(iOS)
            CocoaTextField("PING1 PING2", text: $config.response, onCommit: { addAnswer(tags: config.tags) })
                .isInitialFirstResponder(true)
                .multilineTextAlignment(.center)
                .cornerRadius(8)
                .foregroundColor(.white)
                .textCase(.lowercase)
                .font(.title3)
                .textFieldStyle(PlainTextFieldStyle())
                .cardStyle(Color.hsb(207, 26, 14))
                .padding()
            #else
            TextField(
                "PING1 PING2",
                text: $config.response,
                onCommit: {
                    addAnswer(tags: config.tags)
                }
            )
            .textCase(.lowercase)
            .multilineTextAlignment(.center)
            .foregroundColor(.white)
            .cornerRadius(8)
            .font(.title3)
            .padding()
            #endif

            Spacer()

            AnswerSuggester(input: $config.response)
                .padding([.leading, .trailing])
        }
        .modify {
            #if os(macOS)
            $0.frame(minWidth: 300, minHeight: 450)
            #else
            $0
            #endif
        }
    }

    private func addAnswer(tags: [Tag]) {
        defer { config.dismiss() }
        guard tags.count > 0 else {
            return
        }
        if let editingAnswer = config.editingAnswer {
            viewModel.updateAnswer(editingAnswer, tags: tags)
        } else {
            let answer = Answer(ping: config.pingDate, tags: tags)
            viewModel.createAnswer(answer)
        }
    }
}

#if DEBUG
struct AnswerCreator_Previews: PreviewProvider {
    static var previews: some View {
        Resolver.root = .mock
        return AnswerCreator(config: .constant(AnswerCreatorConfig()))
    }
}
#endif
