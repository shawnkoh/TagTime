//
//  AnswerCreator.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/4/21.
//

import SwiftUI

struct AnswerCreator: View {
    @EnvironmentObject var modelData: ModelData
    var ping: Ping

    @State private var answer: String = ""

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
            Text(dateFormatter.string(from: ping.date))

            Spacer()

            TextField("PING1 PING2", text: $answer, onCommit: {
                let tags = answer.split(separator: " ").map { Tag(name: String($0)) }
                let answer = Answer(ping: ping, tags: tags)
                modelData.answers.append(answer)
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

struct AnswerCreator_Previews: PreviewProvider {
    static var previews: some View {
        AnswerCreator(ping: Stub.pings.first!)
    }
}
