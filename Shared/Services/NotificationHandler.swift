//
//  NotificationHandler.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 8/5/21.
//

import Foundation
import UserNotifications
import Resolver
import Combine

final class NotificationHandler: NSObject {
    @LazyInjected private var authenticationService: AuthenticationService
    @LazyInjected private var answerService: AnswerService
    @LazyInjected private var alertService: AlertService
    @LazyInjected private var answerBuilderExecutor: AnswerBuilderExecutor
    @LazyInjected private var openPingService: OpenPingService

    private var subscribers = Set<AnyCancellable>()
}

extension NotificationHandler: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        guard
            let unixtime = notification.request.content.userInfo["pingDate"] as? String,
            let timeInterval = TimeInterval(unixtime)
        else {
            // TODO: Not sure about this completion handler
            completionHandler([])
            return
        }
        let pingDate = Date(timeIntervalSince1970: timeInterval)
        openPingService.openPing(pingDate)
        // TODO: Not sure about this completion handler.
        completionHandler([.badge, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        guard
            let unixtime = userInfo["pingDate"] as? String,
            let timeInterval = TimeInterval(unixtime)
        else {
            completionHandler()
            return
        }
        let pingDate = Date(timeIntervalSince1970: timeInterval)

        switch response.actionIdentifier {
            case NotificationScheduler.ActionIdentifier.previous:
                guard let previousAnswer = userInfo["previousAnswer"] as? String else {
                    // TODO: Log error
                    completionHandler()
                    return
                }
                answerPing(pingDate, with: previousAnswer, completionHandler: completionHandler)

            case NotificationScheduler.ActionIdentifier.reply:
                guard let response = response as? UNTextInputNotificationResponse else {
                    // TODO: Log error
                    completionHandler()
                    return
                }
                answerPing(pingDate, with: response.userText, completionHandler: completionHandler)

            case UNNotificationDefaultActionIdentifier:
                openPingService.openPing(pingDate)
                completionHandler()

            default:
                break
        }
    }

    private func answerPing(_ ping: Date, with text: String, completionHandler: @escaping () -> Void) {
        // For some reason, this doesn't work if its not wrapped in an async call.
        // I suspect it's because the main thread will conflict with setUser, revisit this when we implement dynamic ping scheduler
        DispatchQueue.global(qos: .utility).async { [self] in
            let tags = text.split(separator: " ").map { Tag($0) }
            let answer = Answer(ping: ping, tags: tags)

            if authenticationService.user.isAuthenticated {
                var builder = AnswerBuilder()
                builder
                    .createAnswer(answer)
                    .execute(with: answerBuilderExecutor)
                    .receive(on: DispatchQueue.global(qos: .utility))
                    .sink(receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            ()
                        case let .failure(error):
                            alertService.present(message: error.localizedDescription)
                        }
                        completionHandler()
                    }, receiveValue: {})
                    .store(in: &subscribers)
            } else {
                // TODO: I don't think this works anymore.
                authenticationService.signIn()
                    // TODO: We should not rely on setUser to trigger the rest of the services. They should be explicitly called.
                    // setUser definitely needs to go.
                    // currently, the services watch AuthenticationService's user, but they receive this on DispatchQueue.main
                    // in order to avoid updating the UI
                    // This call is done on the ground thread, and there is a possibility that it will call completionHandler()
                    // telling the app to shut down, before the other services can complete their calculations.
                    // I suspect the solution is to be very explicit in all the calls
                    .flatMap { user -> AnyPublisher<Void, Error> in
                        var builder = AnswerBuilder()
                        return builder
                            .createAnswer(answer)
                            .execute(with: answerBuilderExecutor)
                    }
                    .receive(on: DispatchQueue.global(qos: .utility))
                    .sink(receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            ()
                        case let .failure(error):
                            alertService.log(error.localizedDescription)
                        }
                        completionHandler()
                    }, receiveValue: {})
                    .store(in: &subscribers)
            }
        }
    }
}
