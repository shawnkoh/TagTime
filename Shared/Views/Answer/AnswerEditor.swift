//
//  AnswerEditor.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/4/21.
//

import SwiftUI

struct AnswerEditor: View {
    @Binding var answer: Answer

    // TODO: Not sure if this is necessary. Probably is
    @State private var answerString: String = ""

    init(answer: Binding<Answer>) {
        // Reference: https://stackoverflow.com/questions/56973959/swiftui-how-to-implement-a-custom-init-with-binding-variables
        self._answer = answer
        self.answerString = answer.wrappedValue.tags.map { $0.name }.joined(separator: " ")
    }

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
            Text(dateFormatter.string(from: answer.ping.date))

            Spacer()

            TextField("PING1 PING2", text: $answerString, onEditingChanged: { _ in }, onCommit: {})
                .autocapitalization(.allCharacters)
                .background(Color.hsb(207, 26, 14))
                .cornerRadius(8)
                .foregroundColor(.white)

            Spacer()
        }
    }
}

struct AnswerEditor_Previews: PreviewProvider {
    static var previews: some View {
        AnswerEditor(answer: .constant(Stub.answers.first!))
    }
}
