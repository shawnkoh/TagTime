//
//  FirestoreBeeminderCredentialService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 12/5/21.
//

import Foundation
import Resolver
import Combine
import Beeminder
import FirebaseFirestoreSwift
import FirebaseFirestore

final class FirestoreBeeminderCredentialService: BeeminderCredentialService {
    @Published private(set) var credential: Beeminder.Credential?
    var credentialPublisher: Published<Credential?>.Publisher { $credential }

    private var userSubscriber: AnyCancellable!
    private var subscribers = Set<AnyCancellable>()
    private var listeners = [ListenerRegistration]()

    @Injected private var authenticationService: AuthenticationService
    @Injected private var alertService: AlertService

    private var user: User {
        authenticationService.user
    }

    init() {
        userSubscriber = authenticationService.userPublisher
            .sink { self.setup(user: $0) }
    }

    private func setup(user: User) {
        subscribers.forEach { $0.cancel() }
        subscribers = []
        listeners.forEach { $0.remove() }
        listeners = []
        credential = nil

        user.credentialDocument.addSnapshotListener { snapshot, error in
            if let error = error {
                self.alertService.present(message: error.localizedDescription)
            }
            self.credential = try? snapshot?.data(as: Beeminder.Credential.self)
        }
        .store(in: &listeners)
    }

    func saveCredential(_ credential: Beeminder.Credential) {
        user.credentialDocument
            .setData(from: credential)
            .errorHandled(by: alertService)
    }

    func removeCredential() {
        user.credentialDocument
            .delete()
            .errorHandled(by: alertService)
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
