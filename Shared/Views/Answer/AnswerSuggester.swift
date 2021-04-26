//
//  AnswerSuggester.swift
//  TagTime
//
//  Created by Shawn Koh on 26/4/21.
//

import SwiftUI

struct AnswerSuggester: View {
    @EnvironmentObject var answerService: AnswerService
    
    let action: ([Tag]) -> Void

    var body: some View {
        if let latestAnswer = answerService.latestAnswer {
            Button(action: { action(latestAnswer.tags) }) {
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
        } else {
            EmptyView()
        }
    }
}

struct AnswerSuggester_Previews: PreviewProvider {
    static var previews: some View {
        AnswerSuggester(action: { _ in })
            .environmentObject(AnswerService.shared)
    }
}
