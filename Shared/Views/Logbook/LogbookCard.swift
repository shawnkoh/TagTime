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
        VStack {
            Text(answer.tagDescription)
            Text(dateFormatter.string(from: answer.ping))
        }
        .onTap { config.edit(answer: answer) }
        .cardButtonStyle(.baseCard)
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
