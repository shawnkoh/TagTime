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

struct AnswerCreator: View {
    @EnvironmentObject var answerService: AnswerService
    @EnvironmentObject var alertService: AlertService
    @Binding var config: AnswerCreatorConfig

    var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack {
            VStack {
                Text("What are you doing")
                Text("RIGHT NOW?")
            }
            Text(dateFormatter.string(from: config.pingDate))

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
            answerService.updateAnswer(editingAnswer, tags: tags)
                .errorHandled(by: alertService)
        } else {
            let answer = Answer(ping: config.pingDate, tags: tags)
            answerService.createAnswerAndUpdateTrackedGoals(answer)
                .errorHandled(by: alertService)
        }
        config.dismiss()
    }
}

struct AnswerCreator_Previews: PreviewProvider {
    @Injected static var answerService: AnswerService
    @Injected static var alertService: AlertService

    static var previews: some View {
        AnswerCreator(config: .constant(AnswerCreatorConfig()))
            .environmentObject(answerService)
            .environmentObject(alertService)
    }
}
