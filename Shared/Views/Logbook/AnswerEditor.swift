//
//  AnswerEditor.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/4/21.
//

import SwiftUI

struct AnswerEditorConfig {
    var isPresented = false
    let pingDate: Date
    var response: String
    var needToSave = false

    var tags: [Tag] {
        response.split(separator: " ").map { Tag($0) }
    }

    init(answer: Answer) {
        self.pingDate = answer.ping
        self.response = answer.tags.joined(separator: " ")
    }

    mutating func present() {
        isPresented = true
        needToSave = false
        // TODO: Not sure if I need to reset response here.
    }

    mutating func dismiss(save: Bool = false) {
        isPresented = false
        needToSave = save
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
            Text(dateFormatter.string(from: config.pingDate))

            Spacer()

            TextField(
                "PING1 PING2",
                text: $config.response,
                onCommit: {
                    let needToSave = config.response.count > 0
                    guard needToSave else {
                        return
                    }
                    config.dismiss(save: needToSave)
                }
            )
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
