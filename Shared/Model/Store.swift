//
//  Store.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/4/21.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift
import Combine
import UserNotifications

// NSObject is required for Store to be UNUserNotificationCenterDelegate
final class Store: NSObject, ObservableObject {
    @Published var pings: [Ping] = []
    @Published var tags: [Tag] = Stub.tags
    @Published var answers: [Answer] = []

    let pingService: PingService

    let settings: Settings
    let user: User

    var alertConfig = AlertConfig()

    var subscribers = Set<AnyCancellable>()

    init(settings: Settings, user: User) {
        self.settings = settings
        self.user = user
        self.pingService = .init(startDate: user.startDate)
        super.init()
        setup()
        setupSubscribers()

        getUnansweredPings() {
            self.pings = $0
        }

        setupNotifications()
    }

    private func setupNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        // TODO: Remove these.
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                // TODO: Log
                print(error)
            }

            guard granted else {
                return
            }
            self.scheduleNotifications()
        }
    }

    private func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings() { settings in
            guard settings.authorizationStatus == .authorized else {
                // TODO: Inform UI
                return
            }
            #if targetEnvironment(simulator)
            let ping = Calendar.current.date(byAdding: .second, value: 10, to: Date())!
            #else
            let ping = self.pingService.nextPing().date
            #endif

            self.scheduleNotification(ping: ping)
        }
    }

    private func scheduleNotification(ping: Ping) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none

        content.title = "It's tag time!"
        // TODO: Not sure if I should display the date since the notification center already displays it.
        content.body = "What are you doing RIGHT NOW (\(formatter.string(from: ping)))?"
        content.badge = 1
        content.sound = .default

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

    private var listener: ListenerRegistration?

    private func setup() {
        self.listener = Firestore.firestore()
            .collection("users")
            .document(user.id)
            .collection("answers")
            .addSnapshotListener() { (snapshot, error) in
                guard let snapshot = snapshot else {
                    // TODO: Log error
                    return
                }
                // TODO: find a better way to handle situations like these
                do {
                    self.answers = try snapshot.documents.compactMap { try $0.data(as: Answer.self) }
                } catch {
                    // TODO: Log error
                }
            }
    }

    private func setupSubscribers() {
        // TODO: This should recompute pings
        settings.$averagePingInterval
            .sink { self.pingService.averagePingInterval = $0 * 60 }
            .store(in: &subscribers )
    }

    func addAnswer(_ answer: Answer) {
        do {
            try Firestore.firestore()
                .collection("users")
                .document(user.id)
                .collection("answers")
                .document(answer.ping.timeIntervalSince1970.description)
                .setData(from: answer) { error in
                    guard let error = error else {
                        return
                    }
                    // TODO: Log error
                    print("unable to save answer", error)
                }
        } catch {
            // TODO: Log error
            print("Unable to add answer")
        }
    }

    func getUnansweredPings(completion: @escaping (([Ping]) -> Void)) {
        let now = Date()
        Firestore.firestore()
            .collection("users")
            .document(user.id)
            .collection("answers")
            .order(by: "ping", descending: true)
            .whereField("ping", isGreaterThanOrEqualTo: user.startDate)
            // TODO: We should probably filter this even more to not incur so many reads.
            .whereField("ping", isLessThanOrEqualTo: now)
            .getDocuments() { (snapshot, error) in
                guard let snapshot = snapshot else {
                    print("returned")
                    // TODO: Log this
                    return
                }
                do {
                    let answerablePings = self.pingService.answerablePings()
                        .map { $0.date }
                    var answerablePingSet = Set(answerablePings)
                    try snapshot.documents
                        .compactMap { try $0.data(as: Answer.self) }
                        .map { $0.ping }
                        .forEach { answerablePingSet.remove($0) }
                    let result = answerablePingSet.sorted()
                    completion(result)
                } catch {
                    // TODO: Log this
                    print("error", error)
                }
            }
    }
}

extension Store: UNUserNotificationCenterDelegate {
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
        print("background", response.actionIdentifier)
        completionHandler()
    }
}
