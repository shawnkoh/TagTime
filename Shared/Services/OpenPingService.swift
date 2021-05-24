//
//  OpenPingService.swift
//  TagTime
//
//  Created by Shawn Koh on 17/5/21.
//

import Foundation
#if os(macOS)
import AppKit
#endif
import Combine
import Resolver

final class OpenPingService {
    @LazyInjected private var pingService: PingService
    @LazyInjected private var answerablePingService: AnswerablePingService

    @Published private(set) var openedPing: Date?
    #if os(macOS)
    private var frontmostApplication: NSRunningApplication?
    #endif

    private var subscribers = Set<AnyCancellable>()

    init() {
        // $status prevents a ping from opening when the service first initialises
        pingService.$status
            .combineLatest(pingService.$answerablePings)
            .compactMap { status, pings -> [Ping]? in
                switch status {
                case .loaded:
                    return pings
                case .loading:
                    return nil
                }
            }
            .compactMap { $0.last?.date }
            // Remove duplicates because status = .loaded and answerablePings.append both trigger
            .removeDuplicates()
            .sink { [weak self] in
                // NSApp and NSWindow are only adjusted here because
                // it does not need to be when opened in notification
                #if os(macOS)
                self?.frontmostApplication = NSWorkspace.shared.frontmostApplication
                if let window = NSApp.windows.first {
                    window.level = .floating
                    window.collectionBehavior = .canJoinAllSpaces
                }
                NSApp.setActivationPolicy(.accessory)
                NSApp.activate(ignoringOtherApps: true)
                #endif
                self?.openPing($0)
            }
            .store(in: &subscribers)

        pingService.$status
            .combineLatest(answerablePingService.$unansweredPings, $openedPing)
            .compactMap { status, unansweredPings, openedPing -> ([Date], Date)? in
                guard status == .loaded, let openedPing = openedPing else {
                    return nil
                }
                return (unansweredPings, openedPing)
            }
            .map { unansweredPings, openedPing -> Bool in
                !unansweredPings.contains(openedPing)
            }
            .filter { $0 }
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.answeredPing()
            }
            .store(in: &subscribers)
    }

    func openPing(_ ping: Date) {
        self.openedPing = ping
    }

    private func answeredPing() {
        openedPing = nil
        #if os(macOS)
        if let window = NSApp.windows.first {
            window.level = .normal
            window.collectionBehavior = .managed
        }
        NSApp.setActivationPolicy(.regular)
        frontmostApplication?.activate()
        frontmostApplication = nil
        #endif
    }
}
