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

final class Store: ObservableObject {
    @Published private(set) var tags: [Tag] = Stub.tags

    let notificationService = NotificationService()

    private var userSubscriber: AnyCancellable = .init({})

    private var subscribers = Set<AnyCancellable>()
    private var listeners = [ListenerRegistration]()

    init() {
        notificationService.delegate = self
        userSubscriber = AuthenticationService.shared.$user
            .receive(on: DispatchQueue.main)
            .sink { self.setup(user: $0) }
    }

    private func setup(user: User?) {
        listeners.forEach { $0.remove() }
        listeners = []
        subscribers.forEach { $0.cancel() }
        subscribers = []

        guard let user = user else {
            return
        }

        notificationService.requestAuthorization() { (granted, error) in
            if let error = error {
                AlertService.shared.present(message: "error while requesting authorisation \(error.localizedDescription)")
            }

            guard granted else {
                AlertService.shared.present(message: "Unable to schedule notifications, not granted permission")
                return
            }

            self.setupNotificationObserver()
        }
    }

    private func setupNotificationObserver() {
        PingService.shared.$answerablePings
            .compactMap { $0.last?.nextPing(averagePingInterval: PingService.shared.averagePingInterval) }
            .combineLatest(AnswerService.shared.$latestAnswer)
            .receive(on: DispatchQueue.main)
            .sink { [self] (nextPing, latestAnswer) in
                var nextPings = [nextPing]
                while nextPings.count < 30 {
                    let next = nextPings.last!.nextPing(averagePingInterval: PingService.shared.averagePingInterval)
                    nextPings.append(next)
                }

                let nextPingDates = nextPings.map { $0.date }

                if let latestAnswer = latestAnswer {
                    notificationService.tryToScheduleNotifications(pings: nextPingDates, previousAnswer: latestAnswer)
                } else {
                    notificationService.tryToScheduleNotifications(pings: nextPingDates, previousAnswer: nil)
                }
            }
            .store(in: &subscribers)
    }
}

extension Store: NotificationServiceDelegate {
    func didAnswerPing(ping: Date, with text: String, completionHandler: @escaping () -> Void) {
        let tags = text.split(separator: " ").map { Tag($0) }
        let answer = Answer(ping: ping, tags: tags)

        DispatchQueue.global(qos: .utility).async {
            let result: Result<Answer, Error>
            if AuthenticationService.shared.user == nil {
                result = AuthenticationService.shared
                    .signIn()
                    .flatMap { _ in AnswerService.shared.addAnswer(answer) }
            } else {
                result = AnswerService.shared.addAnswer(answer)
            }

            DispatchQueue.main.async {
                switch result {
                case .success:
                    ()
                case let .failure(error):
                    // TODO: Figure out how to handle this situation. Maybe re-route the notification?
                    ()
                }
                completionHandler()
            }
        }

    }
}
