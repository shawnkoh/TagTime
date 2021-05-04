//
//  AppService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 17/4/21.
//

import Foundation
import Combine

final class AppService: ObservableObject {
    enum Page: Hashable {
        case missedPingList
        case logbook
        case goalList
        case statistics
        case preferences
    }

    static let shared = AppService()

    @Published var isAuthenticated = false
    @Published var pingNotification = AnswerCreatorConfig()
    @Published var currentPage: Page = .missedPingList

    private var subscribers = Set<AnyCancellable>()

    init() {
        AuthenticationService.shared.$user
            .receive(on: DispatchQueue.main)
            .sink { self.isAuthenticated = $0 != nil }
            .store(in: &subscribers)

        NotificationService.shared.$openedPing
            .receive(on: DispatchQueue.main)
            .sink { [self] in
                if let pingDate = $0 {
                    pingNotification.create(pingDate: pingDate)
                } else {
                    pingNotification.dismiss()
                }
            }
            .store(in: &subscribers)

        BeeminderCredentialService.shared.$credential
            .receive(on: DispatchQueue.main)
            .sink { [self] credential in
                if credential == nil, currentPage == .goalList {
                    currentPage = .missedPingList
                }
            }
            .store(in: &subscribers)
    }

    func signIn() {
        // TODO: I'm not sure if Futures should be called in async thread
        DispatchQueue.global(qos: .utility).async {
            AuthenticationService.shared.signIn()
                .setUser(service: AuthenticationService.shared)
                .errorHandled(by: AlertService.shared)
        }
    }
}
