//
//  AnswerEditor.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/4/21.
//

import SwiftUI

struct AnswerEditorConfig {
    var isPresented = false
    var date: Date
    var response: String

    init(answer: Answer) {
        self.date = answer.ping.date
        self.response = answer.tags.map { $0.name }.joined(separator: " ")
    }

    mutating func present() {
        isPresented = true
    }

    mutating func dismiss() {
        isPresented = false
    }
}

struct AnswerEditor: View {
    @Binding var config: AnswerEditorConfig

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
            Text(dateFormatter.string(from: config.date))

            Spacer()

            TextField("PING1 PING2", text: $config.response)
            .autocapitalization(.allCharacters)
            .multilineTextAlignment(.center)
            .background(Color.hsb(207, 26, 14))
            .cornerRadius(8)
            .foregroundColor(.white)

            Spacer()
        }
    }
}

struct AnswerEditor_Previews: PreviewProvider {
    static var previews: some View {
        AnswerEditor(config: .constant(AnswerEditorConfig(answer: Stub.answers.first!)))
    }
}
