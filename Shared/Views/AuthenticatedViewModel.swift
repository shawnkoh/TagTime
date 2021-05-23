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
    @LazyInjected private var notificationScheduler: NotificationScheduler
    @LazyInjected private var beeminderCredentialService: BeeminderCredentialService
    @LazyInjected private var openPingService: OpenPingService
    @LazyInjected private var pingService: PingService
    @LazyInjected private var router: Router

    @Published var isLoggedIntoBeeminder = false
    @Published var pingNotification = AnswerCreatorConfig()
    #if os(iOS)
    @Published var currentPage: Router.Page = .missedPingList
    #else
    @Published var currentPage: Router.Page? = .missedPingList
    #endif

    private var subscribers = Set<AnyCancellable>()

    init() {
        // Router exists only to communicate between services.
        // AuthenticatedViewModel is the one who actually tells the UI to change.
        router.$currentPage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.currentPage = $0 }
            .store(in: &subscribers)

        openPingService.$openedPing
            .removeDuplicates()
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

                if credential == nil, self?.router.currentPage == .goalList {
                    self?.router.currentPage = .missedPingList
                }
            }
            .store(in: &subscribers)

        // Force notificationScheduler to be injected because it was @LazyInjected
        // TODO: Consider moving userSubscriber somewhere else and making NotificationScheduler
        // a pure API that does not observe.
        notificationScheduler.setup()
    }
}
