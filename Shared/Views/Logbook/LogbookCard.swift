//
//  LogbookCard.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/4/21.
//

import SwiftUI

struct LogbookCard: View {
    var answer: Answer

    @State var config: AnswerEditorConfig

    init(answer: Answer) {
        self.answer = answer
        self._config = State(initialValue: AnswerEditorConfig(answer: answer))
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        Button(action: { config.present() }) {
            HStack {
                Spacer()
                VStack {
                    Text(answer.tags.map({ $0.name }).joined(separator: " "))
                    Text(dateFormatter.string(from: answer.ping))
                }
                .foregroundColor(.white)
                Spacer()
            }
        }
        .background(Color.hsb(211, 26, 86))
        .cornerRadius(10)
        .sheet(isPresented: $config.isPresented, onDismiss: {
            guard config.needToSave else {
                return
            }
            // TODO: Save it!
        }) {
            AnswerEditor(config: $config)
        }

    }
}

struct LogbookCard_Previews: PreviewProvider {
    static var previews: some View {
        LogbookCard(answer: Stub.answers.first!)
    }
}
