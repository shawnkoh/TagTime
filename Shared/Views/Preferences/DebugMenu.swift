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

            Button(action: {
                NotificationService.shared.scheduleNotification(
                    ping: .init(timeIntervalSinceNow: 7),
                    badge: AnswerService.shared.unansweredPings.count + 1
                )
            }) {
                HStack {
                    Spacer()
                    Text("Schedule notification in 7 seconds")
                        .foregroundColor(.primary)
                        .padding()
                    Spacer()
                }
                .background(Color.hsb(223, 69, 90))
                .cornerRadius(8)
            }

            Button(action: {
                AnswerService.shared.deleteAllAnswers()
            }) {
                HStack {
                    Spacer()
                    Text("Delete all answers")
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

struct DebugMenu_Previews: PreviewProvider {
    static var previews: some View {
        DebugMenu()
    }
}
#endif
