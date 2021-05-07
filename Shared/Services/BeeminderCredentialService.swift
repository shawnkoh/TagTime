//
//  BeeminderService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/5/21.
//

import Foundation
import Combine
import FirebaseFirestoreSwift
import FirebaseFirestore
import Beeminder

final class BeeminderCredentialService: ObservableObject {
    static let shared = BeeminderCredentialService(authenticationService: AuthenticationService.shared)

    @Published private(set) var credential: Beeminder.Credential?

    private var userSubscriber: AnyCancellable!
    private var subscribers = Set<AnyCancellable>()
    private var listeners = [ListenerRegistration]()

    private let authenticationService: AuthenticationService

    private var user: User {
        authenticationService.user
    }

    init(authenticationService: AuthenticationService) {
        self.authenticationService = authenticationService
        userSubscriber = authenticationService.$user
            .sink { self.setup(user: $0) }
    }

    func setup(user: User) {
        subscribers.forEach { $0.cancel() }
        subscribers = []
        listeners.forEach { $0.remove() }
        listeners = []
        user.credentialDocument.addSnapshotListener { snapshot, error in
            if let error = error {
                AlertService.shared.present(message: error.localizedDescription)
            }
            let credential = try? snapshot?.data(as: Beeminder.Credential.self)
            self.credential = credential
        }
        .store(in: &listeners)
    }

    func saveCredential(_ credential: Beeminder.Credential, user: User) {
        user.credentialDocument
            .setData(from: credential)
            .errorHandled(by: AlertService.shared)
    }

    func saveCredential(_ credential: Beeminder.Credential) {
        saveCredential(credential, user: user)
    }

    func removeCredential(user: User) {
        user.credentialDocument
            .delete()
            .errorHandled(by: AlertService.shared)
    }

    func removeCredential() {
        removeCredential(user: user)
    }
}

private extension User {
    var beeminderCollection: CollectionReference {
        self.userDocument.collection("beeminder")
    }

    var credentialDocument: DocumentReference {
        beeminderCollection.document("credential")
    }
}
