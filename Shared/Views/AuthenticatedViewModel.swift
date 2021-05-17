//
//  AuthenticatedViewModel.swift
//  TagTime
//
//  Created by Shawn Koh on 13/5/21.
//

import Combine
import Resolver
import Foundation
#if os(macOS)
import AppKit
#endif

final class AuthenticatedViewModel: ObservableObject {
    enum Page: Hashable {
        case missedPingList
        case logbook
        case goalList
        case statistics
        case preferences
    }

    @Published var isLoggedIntoBeeminder = false
    @Published var pingNotification = AnswerCreatorConfig()
    #if os(iOS)
    @Published var currentPage: Page = .missedPingList
    #else
    @Published var currentPage: Page? = .missedPingList
    #endif

    private var subscribers = Set<AnyCancellable>()
    @LazyInjected private var notificationScheduler: NotificationScheduler
    @LazyInjected private var beeminderCredentialService: BeeminderCredentialService
    @LazyInjected private var openPingService: OpenPingService
    @LazyInjected private var pingService: PingService

    init() {
        pingService.$answerablePings
            // TODO: AnswerablePings should be an enum to define loading state instead of relying on this
            // It still results in an unnecessary call
            .filter { $0.count > 0 }
            .sink { pings in
                if let ping = pings.last {
                    self.openPingService.openPing(ping.date)
                }
            }
            .store(in: &subscribers)

        openPingService.$openedPing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                #if os(macOS)
                NSApplication.shared.activate(ignoringOtherApps: true)
                #endif
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
