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
    @Injected private var answerService: AnswerService
    @Injected private var alertService: AlertService

    private(set) lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    func updateAnswer(_ answer: Answer, tags: [Tag]) {
        answerService.updateAnswer(answer, tags: tags)
            .errorHandled(by: alertService)
    }

    func createAnswerAndUpdateTrackedGoals(_ answer: Answer) {
        answerService.createAnswerAndUpdateTrackedGoals(answer)
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
                Text("RIGHT NOW?")
            }
            Text(viewModel.dateFormatter.string(from: config.pingDate))

            Spacer()

            CocoaTextField("PING1 PING2", text: $config.response, onCommit: { addAnswer(tags: config.tags) })
                .isInitialFirstResponder(true)
                .autocapitalization(.allCharacters)
                .multilineTextAlignment(.center)
                .background(Color.hsb(207, 26, 14))
                .cornerRadius(8)
                .foregroundColor(.white)

            Spacer()

            AnswerSuggester(keyword: $config.response)
        }
    }

    private func addAnswer(tags: [Tag]) {
        guard tags.count > 0 else {
            return
        }
        if let editingAnswer = config.editingAnswer {
            viewModel.updateAnswer(editingAnswer, tags: tags)
        } else {
            let answer = Answer(ping: config.pingDate, tags: tags)
            viewModel.createAnswerAndUpdateTrackedGoals(answer)
        }
        config.dismiss()
    }
}

struct AnswerCreator_Previews: PreviewProvider {
    static var previews: some View {
        AnswerCreator(config: .constant(AnswerCreatorConfig()))
    }
}
