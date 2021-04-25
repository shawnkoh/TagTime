//
//  LogbookCard.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/4/21.
//

import SwiftUI

struct LogbookCard: View {
    var answer: Answer

    @EnvironmentObject var answerService: AnswerService
    @EnvironmentObject var alertService: AlertService

    @State var config = AnswerCreatorConfig()

    init(answer: Answer) {
        self.answer = answer
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        Button(action: { config.present(pingDate: answer.ping, response: answer.tagDescription) }) {
            HStack {
                Spacer()
                VStack {
                    Text(answer.tagDescription)
                    Text(dateFormatter.string(from: answer.ping))
                }
                .foregroundColor(.white)
                Spacer()
            }
        }
        .background(Color.hsb(211, 26, 86))
        .cornerRadius(10)
        .sheet(isPresented: $config.isPresented) {
            AnswerCreator(config: $config)
                .environmentObject(self.answerService)
                .environmentObject(self.alertService)
        }

    }
}

struct LogbookCard_Previews: PreviewProvider {
    static var previews: some View {
        LogbookCard(answer: Stub.answers.first!)
    }
}
