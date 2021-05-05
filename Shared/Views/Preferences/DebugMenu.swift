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

            Text("Schedule notification in 5 seconds")
                .onTap {
                    let timeInterval = Date(timeIntervalSinceNow: 5).timeIntervalSince1970.rounded()
                    let pingDate = Date(timeIntervalSince1970: timeInterval)
                    NotificationService.shared.scheduleNotification(
                        ping: pingDate,
                        badge: AnswerService.shared.unansweredPings.count,
                        previousAnswer: AnswerService.shared.latestAnswer
                    )
                }

            Text("Delete all answers")
                .onTap { AnswerService.shared.deleteAllAnswers() }

            Text("Reset User Start Date")
                .onTap { AuthenticationService.shared.resetUserStartDate() }

            Text("Reset Tag Cache")
                .onTap { TagService.shared.resetTagCache() }
        }
        .cardButtonStyle(.baseCard)
    }
}

struct DebugMenu_Previews: PreviewProvider {
    static var previews: some View {
        DebugMenu()
    }
}
#endif
