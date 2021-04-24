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

            button("Schedule notification in 7 seconds") {
                NotificationService.shared.scheduleNotification(
                    ping: .init(timeIntervalSinceNow: 7),
                    badge: AnswerService.shared.unansweredPings.count + 1
                )
            }

            button("Delete all answers") {
                AnswerService.shared.deleteAllAnswers()
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
