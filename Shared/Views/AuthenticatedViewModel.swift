//
//  AuthenticatedViewModel.swift
//  TagTime
//
//  Created by Shawn Koh on 13/5/21.
//

import Combine
import Resolver
import Foundation

final class AuthenticatedViewModel: ObservableObject {
    enum Page: Hashable {
        case missedPingList
        case logbook
        case goalList
        case statistics
        case preferences
    }

    @Published var isAuthenticated = false
    @Published var isLoggedIntoBeeminder = false
    @Published var pingNotification = AnswerCreatorConfig()
    // TODO: iPad should use the Mac Sidebar navigation instead
    #if os(iOS)
    @Published var currentPage: Page = .missedPingList
    #else
    @Published var currentPage: Page? = .missedPingList
    #endif

    private var subscribers = Set<AnyCancellable>()
    @Injected private var authenticationService: AuthenticationService
    @Injected private var notificationHandler: NotificationHandler
    @Injected private var notificationScheduler: NotificationScheduler
    @Injected private var beeminderCredentialService: BeeminderCredentialService

    init() {
        authenticationService.userPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isAuthenticated = $0.isAuthenticated }
            .store(in: &subscribers)

        notificationHandler.$openedPing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                if let pingDate = $0 {
                    self?.pingNotification.create(pingDate: pingDate)
                } else {
                    self?.pingNotification.dismiss()
                }
            }
            .store(in: &subscribers)

        beeminderCredentialService.credentialPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] credential in
                self?.isLoggedIntoBeeminder = credential != nil

                if credential == nil, self?.currentPage == .goalList {
                    self?.currentPage = .missedPingList
                }
            }
            .store(in: &subscribers)
    }
}
