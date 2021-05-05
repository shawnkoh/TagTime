//
//  DebugMenu.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 25/4/21.
//

#if DEBUG
import SwiftUI

struct DebugMenu: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Debug Mode")
                .font(.title)
                .bold()

            Card(text: "Schedule notification in 5 seconds")
                .onPress {
                    let timeInterval = Date(timeIntervalSinceNow: 5).timeIntervalSince1970.rounded()
                    let pingDate = Date(timeIntervalSince1970: timeInterval)
                    NotificationService.shared.scheduleNotification(
                        ping: pingDate,
                        badge: AnswerService.shared.unansweredPings.count,
                        previousAnswer: AnswerService.shared.latestAnswer
                    )
                }

            Card(text: "Delete all answers")
                .onPress { AnswerService.shared.deleteAllAnswers() }

            Card(text: "Reset User Start Date")
                .onPress { AuthenticationService.shared.resetUserStartDate() }

            Card(text: "Reset Tag Cache")
                .onPress { TagService.shared.resetTagCache() }
        }
    }
}

struct DebugMenu_Previews: PreviewProvider {
    static var previews: some View {
        DebugMenu()
    }
}
#endif
