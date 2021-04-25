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

    var tags: [String] {
        response.split(separator: " ").map { Tag($0) }
    }

    mutating func present(pingDate: Date, response: String = "") {
        isPresented = true
        self.pingDate = pingDate
        self.response = response
    }

    mutating func dismiss() {
        isPresented = false
    }
}

// This is intended to replace AnswerEditor & MissedPingAnswerer
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

            TextField("PING1 PING2", text: $config.response, onCommit: { addAnswer(tags: config.tags) })
                .autocapitalization(.allCharacters)
                .multilineTextAlignment(.center)
                .background(Color.hsb(207, 26, 14))
                .cornerRadius(8)
                .foregroundColor(.white)

            Spacer()

            if let latestAnswer = answerService.latestAnswer {
                Button(action: { addAnswer(tags: latestAnswer.tags) }) {
                    HStack {
                        Spacer()
                        Text(latestAnswer.tagDescription)
                            .foregroundColor(.primary)
                            .padding()
                        Spacer()
                    }
                    .background(Color.hsb(223, 69, 90))
                    .cornerRadius(8)
                }
            }
        }
    }

    private func addAnswer(tags: [Tag]) {
        guard tags.count > 0 else {
            return
        }
        let answer = Answer(ping: config.pingDate, tags: tags)
        DispatchQueue.global(qos: .utility).async {
            let result = answerService.addAnswer(answer)
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // TODO: Not sure what to do here
                    ()
                case let .failure(error):
                    alertService.present(message: error.localizedDescription)
                }
            }
        }
        config.dismiss()
    }
}

struct AnswerCreator_Previews: PreviewProvider {
    static var previews: some View {
        AnswerCreator(config: .constant(AnswerCreatorConfig()))
            .environmentObject(AnswerService.shared)
            .environmentObject(AlertService.shared)
    }
}
