//
//  AnswerCreator.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 24/4/21.
//

import SwiftUI

struct AnswerCreatorConfig {
    var isPresented = false
    var pingDate = Date()
    var response = ""
    var needsSave = false

    var tags: [String] {
        response.split(separator: " ").map { Tag($0) }
    }

    mutating func present(pingDate: Date) {
        isPresented = true
        self.pingDate = pingDate
        response = ""
        needsSave = false
    }

    mutating func dismiss(save: Bool = false) {
        isPresented = false
        needsSave = save
    }
}

// This is intended to replace AnswerEditor & MissedPingAnswerer
struct AnswerCreator: View {
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

struct AnswerCreator_Previews: PreviewProvider {
    static var previews: some View {
        AnswerCreator(config: .constant(AnswerCreatorConfig()))
    }
}
