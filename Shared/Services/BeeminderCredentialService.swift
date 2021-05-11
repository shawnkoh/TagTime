//
//  BeeminderService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/5/21.
//

import Foundation
import Combine
import Beeminder

protocol BeeminderCredentialService {
    var credential: Beeminder.Credential? { get }
    var credentialPublisher: Published<Beeminder.Credential?>.Publisher { get }

    func saveCredential(_ credential: Beeminder.Credential)
    func removeCredential()
}
