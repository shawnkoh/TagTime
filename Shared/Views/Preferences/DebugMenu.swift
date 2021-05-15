//
//  DebugMenu.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 25/4/21.
//

#if DEBUG
import SwiftUI
import Resolver
import Firebase

final class DebugViewModel: ObservableObject {
    @LazyInjected private var answerService: AnswerService
    @LazyInjected private var authenticationService: AuthenticationService
    @LazyInjected private var tagService: TagService
    @LazyInjected private var notificationScheduler: NotificationScheduler
    @LazyInjected private var answerablePingService: AnswerablePingService
    @LazyInjected private var goalService: GoalService
    @LazyInjected private var alertService: AlertService

    func scheduleNotification() {
        let timeInterval = Date(timeIntervalSinceNow: 5).timeIntervalSince1970.rounded()
        let pingDate = Date(timeIntervalSince1970: timeInterval)
        notificationScheduler.scheduleNotification(
            ping: pingDate,
            badge: answerablePingService.unansweredPings.count,
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

    func clearPersistence() {
        Firestore.firestore().clearPersistence { error in
            if let error = error {
                self.alertService.present(message: error.localizedDescription)
            }
        }
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

            Text("Clear Persistence")
                .onDoubleTap("Tap again to perform") { viewModel.clearPersistence() }

            Spacer()
        }
        .background(.modalBackground)
        .cardButtonStyle(.modalCard)
    }
}

struct DebugMenu_Previews: PreviewProvider {
    static var previews: some View {
        #if DEBUG
        Resolver.root = .mock
        #endif
        return DebugMenu()
    }
}
#endif
