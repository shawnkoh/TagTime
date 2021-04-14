//
//  NotificationService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 12/4/21.
//

import Foundation
import UserNotifications

public protocol NotificationServiceDelegate {
    func didAnswerPing(ping: Date, with text: String)
}

// NSObject is required for NotificationService to be UNUserNotificationCenterDelegate
public final class NotificationService: NSObject {
    public enum ActionIdentifier {
        static let open = "OPEN_ACTION"
        static let previous = "PREVIOUS_ACTION"
        static let reply = "REPLY_ACTION"
    }

    public enum CategoryIdentifier {
        static let ping = "PING_CATEGORY"
    }

    private(set) var category: UNNotificationCategory

    let center = UNUserNotificationCenter.current()
    let openAction = UNNotificationAction(identifier: ActionIdentifier.open, title: "Open", options: .foreground)
    let replyAction = UNTextInputNotificationAction(identifier: ActionIdentifier.reply, title: "Reply", options: .destructive)

    public var delegate: NotificationServiceDelegate?

    public override init() {
        self.category = UNNotificationCategory(
            identifier: CategoryIdentifier.ping,
            actions: [openAction, replyAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: nil,
            categorySummaryFormat: nil,
            options: [.allowAnnouncement, .allowInCarPlay, .customDismissAction]
        )
        super.init()
        center.delegate = self
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
            let title = previousAnswer.tags.joined(separator: " ")
            let previousAction = UNNotificationAction(identifier: ActionIdentifier.previous, title: title, options: .destructive)
            self.category = UNNotificationCategory(
                identifier: CategoryIdentifier.ping,
                actions: [previousAction, replyAction, openAction],
                intentIdentifiers: [],
                hiddenPreviewsBodyPlaceholder: nil,
                categorySummaryFormat: nil,
                options: [.allowAnnouncement, .allowInCarPlay, .customDismissAction]
            )
        } else {
            self.category = UNNotificationCategory(
                identifier: CategoryIdentifier.ping,
                actions: [replyAction, openAction],
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

        pings.forEach { scheduleNotification(ping: $0) }
    }

    /// Do not call this function. Only used for testing
    func scheduleNotification(ping: Date) {
        let content = UNMutableNotificationContent()

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none

        content.title = "It's tag time!"
        // TODO: Not sure if I should display the date since the notification center already displays it.
        content.body = "What are you doing RIGHT NOW (\(formatter.string(from: ping)))?"
        content.badge = 1
        content.sound = .default
        content.categoryIdentifier = CategoryIdentifier.ping
        // TODO: Assign custom info to userInfo
        content.targetContentIdentifier = ping.documentId

        let dateComponents = Calendar.current.dateComponents([.day, .month, .year, .second, .minute, .hour], from: ping)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: ping.description, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                // TODO: Log
                print("error scheduling notification", error)
            }
        }
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("foreground")
        completionHandler([])
//        completionHandler([.badge, .banner, .list, .sound])
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        guard let delegate = delegate else {
            return
        }

        switch response.actionIdentifier {
            case Self.ActionIdentifier.previous:
                ()
            case Self.ActionIdentifier.reply:
                guard
                    let response = response as? UNTextInputNotificationResponse,
                    let documentId = response.notification.request.content.targetContentIdentifier,
                    let timeInterval = TimeInterval(documentId)
                else {
                    // TODO: Log error
                    // Maybe AlertService should be a global variable rather than inside Store
                    // Either that or we can just expose it via the delegate
                    return
                }

                let ping = Date(timeIntervalSince1970: timeInterval)
                delegate.didAnswerPing(ping: ping, with: response.userText)

            case Self.ActionIdentifier.open:
                ()
            default:
                break
        }
        completionHandler()
    }
}
