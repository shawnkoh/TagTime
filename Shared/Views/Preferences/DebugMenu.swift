//
//  DebugMenu.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 25/4/21.
//

#if DEBUG
import SwiftUI
import Resolver

final class DebugViewModel: ObservableObject {
    @Injected private var answerService: AnswerService
    @Injected private var authenticationService: AuthenticationService
    @Injected private var tagService: TagService
    @Injected private var notificationScheduler: NotificationScheduler
    @Injected private var pingService: PingService

    func scheduleNotification() {
        let timeInterval = Date(timeIntervalSinceNow: 5).timeIntervalSince1970.rounded()
        let pingDate = Date(timeIntervalSince1970: timeInterval)
        notificationScheduler.scheduleNotification(
            ping: pingDate,
            badge: pingService.unansweredPings.count,
            previousAnswer: answerService.latestAnswer
        )
    }

    func deleteAllAnswers() {
        answerService.deleteAllAnswers()
    }

    func resetUserStartDate() {
        authenticationService.resetUserStartDate()
    }

    func resetTagCache() {
        tagService.resetTagCache()
    }
}

struct DebugMenu: View {
    @StateObject private var viewModel = DebugViewModel()

    var body: some View {
        VStack(alignment: .leading) {
            Text("Debug Mode")
                .font(.title)
                .bold()
                .padding()

            Text("Schedule notification in 5 seconds")
                .onDoubleTap("Tap again to confirm") { viewModel.scheduleNotification() }

            Text("Delete all answers")
                .onDoubleTap("Tap again to confirm") { viewModel.deleteAllAnswers() }

            Text("Reset User Start Date")
                .onDoubleTap("Tap again to confirm") { viewModel.resetUserStartDate() }

            Text("Reset Tag Cache")
                .onDoubleTap("Tap again to confirm") { viewModel.resetTagCache() }

            Spacer()
        }
        .background(.modalBackground)
        .cardButtonStyle(.modalCard)
    }
}

struct DebugMenu_Previews: PreviewProvider {
    static var previews: some View {
        DebugMenu()
    }
}
#endif
