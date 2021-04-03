//
//  AnswerEditor.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/4/21.
//

import SwiftUI

struct AnswerEditor: View {
    @EnvironmentObject var modelData: ModelData

    var answer: Answer

    // TODO: Not sure if this is necessary. Probably is
    @State private var response: String = ""

    init(answer: Answer) {
        self.answer = answer
        self.response = answer.tags.map { $0.name }.joined(separator: " ")
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

            TextField("PING1 PING2", text: $response, onCommit: {
                print("answer.id", answer.id)
                print(modelData.answers.map { $0.id })
                guard var answer = modelData.answers.first(where: { $0.id == answer.id }) else {
                    print("returned")
                    return
                }
                answer.tags = response.split(separator: " ").map { Tag(name: String($0)) }
                print("answer.tags", answer.tags)
            })
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
        AnswerEditor(answer: Stub.answers.first!)
    }
}
