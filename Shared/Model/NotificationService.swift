//
//  NotificationService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 12/4/21.
//

import Foundation
import UserNotifications

// NSObject is required for NotificationService to be UNUserNotificationCenterDelegate
final class NotificationService: NSObject {
    enum ActionIdentifier {
        static let open = "OPEN_ACTION"
        static let previous = "PREVIOUS_ACTION"
        static let reply = "REPLY_ACTION"
    }

    enum CategoryIdentifier {
        static let ping = "PING_CATEGORY"
    }

    private(set) var category: UNNotificationCategory

    let center = UNUserNotificationCenter.current()
    let openAction = UNNotificationAction(identifier: ActionIdentifier.open, title: "Open", options: .foreground)
    let replyAction = UNTextInputNotificationAction(identifier: ActionIdentifier.reply, title: "Reply", options: .destructive)

    override init() {
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

    func requestAuthorization(completionHandler: @escaping (Bool, Error?) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge], completionHandler: completionHandler)
    }

    /// Fails if user did not grant authorisation
    // TODO: This needs to be reworked when the authorisation workflow has been thought through
    func tryToScheduleNotifications(pings: [Ping], previousAnswer: Answer?) {
        center.getNotificationSettings() { settings in
            guard settings.authorizationStatus == .authorized else {
                // TODO: Inform UI
                return
            }

            self.scheduleNotifications(pings: pings, previousAnswer: previousAnswer)
        }
    }

    private func scheduleNotifications(pings: [Ping], previousAnswer: Answer?) {
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

    private func scheduleNotification(ping: Ping) {
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
        content.targetContentIdentifier = ping.description

        #if targetEnvironment(simulator)
        let dateComponents = Calendar.current.dateComponents([.day, .month, .year, .second, .minute, .hour], from: Date().addingTimeInterval(7))
        #else
        let dateComponents = Calendar.current.dateComponents([.day, .month, .year, .second, .minute, .hour], from: ping)
        #endif

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
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("foreground")
        completionHandler([])
//        completionHandler([.badge, .banner, .list, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
            case Self.ActionIdentifier.previous:
                ()
            case Self.ActionIdentifier.reply:
                ()
            case Self.ActionIdentifier.open:
                ()
            default:
                break
        }
        completionHandler()
    }
}
