//
//  MockBeeminderCredentialService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 12/5/21.
//

import Foundation
import Beeminder
import Combine
import Resolver

final class MockBeeminderCredentialService: BeeminderCredentialService {
    @LazyInjected private var authenticationService: AuthenticationService

    @Published var credential: Credential?
    var credentialPublisher: Published<Credential?>.Publisher { $credential }

    private var subscribers = Set<AnyCancellable>()

    init() {
        authenticationService.userPublisher
            .sink { user in
                guard user.isAuthenticated else {
                    self.credential = nil
                    return
                }
                self.credential = .init(username: "mock", accessToken: "abc")
            }
            .store(in: &subscribers)
    }

    func saveCredential(_ credential: Credential) {
        self.credential = credential
    }

    func removeCredential() {
        self.credential = nil
    }
}
