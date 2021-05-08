//
//  NotificationScheduler.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 12/4/21.
//

import Foundation
import UserNotifications
import Combine
import UIKit
import Resolver

public final class NotificationScheduler: ObservableObject {
    public enum ActionIdentifier {
        static let previous = "PREVIOUS_ACTION"
        static let reply = "REPLY_ACTION"
    }

    public enum CategoryIdentifier {
        static let ping = "PING_CATEGORY"
    }

    private(set) var category: UNNotificationCategory

    let center = UNUserNotificationCenter.current()
    let replyAction = UNTextInputNotificationAction(identifier: ActionIdentifier.reply, title: "Reply", options: .destructive)

    private var userSubscriber: AnyCancellable = .init({})

    private var subscribers = Set<AnyCancellable>()

    @Injected private var alertService: AlertService
    @Injected private var authenticationService: AuthenticationService
    @Injected private var pingService: PingService
    @Injected private var answerService: AnswerService

    private var user: User {
        authenticationService.user
    }

    public init() {
        self.category = UNNotificationCategory(
            identifier: CategoryIdentifier.ping,
            actions: [replyAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: nil,
            categorySummaryFormat: nil,
            options: [.allowAnnouncement, .allowInCarPlay, .customDismissAction]
        )
        userSubscriber = authenticationService.$user
            .receive(on: DispatchQueue.main)
            .sink { self.setup(user: $0) }
    }

    private func setup(user: User) {
        subscribers.forEach { $0.cancel() }
        subscribers = []

        requestAuthorization() { (granted, error) in
            if let error = error {
                self.alertService.present(message: "error while requesting authorisation \(error.localizedDescription)")
            }

            guard granted else {
                self.alertService.present(message: "Unable to schedule notifications, not granted permission")
                return
            }

            self.setupNotificationObserver()
        }
    }

    private func setupNotificationObserver() {
        pingService.$unansweredPings
            .map { $0.count }
            .receive(on: DispatchQueue.main)
            .sink { UIApplication.shared.applicationIconBadgeNumber = $0 }
            .store(in: &subscribers)

        pingService.$answerablePings
            .compactMap { $0.last?.nextPing(averagePingInterval: self.pingService.averagePingInterval) }
            .map { nextPing -> [Date] in
                var nextPings = [nextPing]
                while nextPings.count < 30 {
                    let next = nextPings.last!.nextPing(averagePingInterval: self.pingService.averagePingInterval)
                    nextPings.append(next)
                }
                return nextPings.map { $0.date }
            }
            .combineLatest(answerService.$latestAnswer)
            .receive(on: DispatchQueue.main)
            .sink { [self] (nextPings, latestAnswer) in
                tryToScheduleNotifications(pings: nextPings, previousAnswer: latestAnswer)
            }
            .store(in: &subscribers)
    }

    public func requestAuthorization(completionHandler: @escaping (Bool, Error?) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge], completionHandler: completionHandler)
    }

    /// Fails if user did not grant authorisation
    // TODO: This needs to be reworked when the authorisation workflow has been thought through
    public func tryToScheduleNotifications(pings: [Date], previousAnswer: Answer?) {
        center.getNotificationSettings() { settings in
            guard settings.authorizationStatus == .authorized else {
                // TODO: Inform UI
                return
            }

            self.scheduleNotifications(pings: pings, previousAnswer: previousAnswer)
        }
    }

    private func scheduleNotifications(pings: [Date], previousAnswer: Answer?) {
        if let previousAnswer = previousAnswer {
            let previousAction = UNNotificationAction(identifier: ActionIdentifier.previous, title: previousAnswer.tagDescription, options: .destructive)
            self.category = UNNotificationCategory(
                identifier: CategoryIdentifier.ping,
                actions: [previousAction, replyAction],
                intentIdentifiers: [],
                hiddenPreviewsBodyPlaceholder: nil,
                categorySummaryFormat: nil,
                options: [.allowAnnouncement, .allowInCarPlay, .customDismissAction]
            )
        } else {
            self.category = UNNotificationCategory(
                identifier: CategoryIdentifier.ping,
                actions: [replyAction],
                intentIdentifiers: [],
                hiddenPreviewsBodyPlaceholder: nil,
                categorySummaryFormat: nil,
                options: [.allowAnnouncement, .allowInCarPlay, .customDismissAction]
            )
        }

        center.setNotificationCategories([category])
        // TODO: I'm not sure how to deal with these yet
        center.removeAllDeliveredNotifications()

        center.removeAllPendingNotificationRequests()

        pings.enumerated().forEach { index, ping in
            scheduleNotification(ping: ping, badge: pingService.unansweredPings.count + index + 1, previousAnswer: previousAnswer)
        }
    }

    /// Do not call this function. Only used for testing
    func scheduleNotification(ping: Date, badge: Int, previousAnswer: Answer?) {
        // TODO: Strip microseconds from pingDate
        let content = UNMutableNotificationContent()

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none

        content.title = "It's tag time!"
        // TODO: Not sure if I should display the date since the notification center already displays it.
        content.body = "What are you doing RIGHT NOW (\(formatter.string(from: ping)))?"
        content.badge = NSNumber(integerLiteral: badge)
        content.sound = .default
        content.categoryIdentifier = CategoryIdentifier.ping
        let unixtime = ping.timeIntervalSince1970.description

        // Preferred using userInfo because that's what the documentation uses. Not sure about other properties yet.
        // Reference:: https://developer.apple.com/documentation/usernotifications/handling_notifications_and_notification-related_actions
        content.userInfo["pingDate"] = unixtime
        // Store previousAnswer here rather than rely on the Category's title because
        // the category gets set only when scheduling a notification
        // Do not retrieve previousAnswer from AnswerService because it might be different.
        // There should be a singular source of truth.
        content.userInfo["previousAnswer"] = previousAnswer?.tagDescription

        let dateComponents = Calendar.current.dateComponents([.day, .month, .year, .second, .minute, .hour], from: ping)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: unixtime, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                self.alertService.present(message: error.localizedDescription)
            }
        }
    }
}