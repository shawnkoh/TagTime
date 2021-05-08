//
//  AppService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 17/4/21.
//

import Foundation
import Combine
import Resolver

final class AppService: ObservableObject {
    enum Page: Hashable {
        case missedPingList
        case logbook
        case goalList
        case statistics
        case preferences
    }

    @Published var isAuthenticated = false
    @Published var pingNotification = AnswerCreatorConfig()
    @Published var currentPage: Page = .missedPingList

    private var subscribers = Set<AnyCancellable>()
    @Injected private var authenticationService: AuthenticationService
    @Injected private var notificationHandler: NotificationHandler
    @Injected private var notificationScheduler: NotificationScheduler
    @Injected private var beeminderCredentialService: BeeminderCredentialService
    @Injected private var alertService: AlertService

    init() {
        authenticationService.$user
            .receive(on: DispatchQueue.main)
            .sink { self.isAuthenticated = $0.id != AuthenticationService.unauthenticatedUserId }
            .store(in: &subscribers)

        notificationHandler.$openedPing
            .receive(on: DispatchQueue.main)
            .sink { [self] in
                if let pingDate = $0 {
                    pingNotification.create(pingDate: pingDate)
                } else {
                    pingNotification.dismiss()
                }
            }
            .store(in: &subscribers)

        beeminderCredentialService.$credential
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
        DispatchQueue.global(qos: .utility).async { [self] in
            authenticationService.signIn()
                .setUser(service: authenticationService)
                .errorHandled(by: alertService)
        }
    }
}
