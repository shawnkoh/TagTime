//
//  DebugMenu.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 25/4/21.
//

#if DEBUG
import SwiftUI

struct DebugMenu: View {
    @ViewBuilder
    private func button(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(text)
                    .foregroundColor(.primary)
                    .padding()
                Spacer()
            }
            .background(Color.hsb(223, 69, 90))
            .cornerRadius(8)
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Debug Mode")
                .font(.title)
                .bold()

            button("Schedule notification in 5 seconds") {
                let timeInterval = Date(timeIntervalSinceNow: 5).timeIntervalSince1970.rounded()
                let pingDate = Date(timeIntervalSince1970: timeInterval)
                NotificationService.shared.scheduleNotification(
                    ping: pingDate,
                    badge: AnswerService.shared.unansweredPings.count,
                    previousAnswer: AnswerService.shared.latestAnswer
                )
            }

            button("Delete all answers") {
                AnswerService.shared.deleteAllAnswers()
            }

            button("Reset User Start Date") {
                AuthenticationService.shared.resetUserStartDate()
            }
        }
    }
}

struct DebugMenu_Previews: PreviewProvider {
    static var previews: some View {
        DebugMenu()
    }
}
#endif
