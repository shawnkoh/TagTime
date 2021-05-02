//
//  AppService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 17/4/21.
//

import Foundation
import Combine

final class AppService: ObservableObject {
    static let shared = AppService()

    @Published var isAuthenticated = false
    @Published var pingNotification = AnswerCreatorConfig()

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
