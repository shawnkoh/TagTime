//
//  MockBeeminderCredentialService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 12/5/21.
//

import Foundation
import Beeminder
import Combine

final class MockBeeminderCredentialService: BeeminderCredentialService {
    @Published var credential: Credential?
    var credentialPublisher: Published<Credential?>.Publisher { $credential }

    init() {}

    func saveCredential(_ credential: Credential) {
        self.credential = credential
    }

    func removeCredential() {
        self.credential = nil
    }
}
