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
import Resolver

final class BeeminderCredentialService: ObservableObject {
    @Published private(set) var credential: Beeminder.Credential?

    private var userSubscriber: AnyCancellable!
    private var subscribers = Set<AnyCancellable>()
    private var listeners = [ListenerRegistration]()

    @Injected private var authenticationService: AuthenticationService
    @Injected private var alertService: AlertService

    private var user: User {
        authenticationService.user
    }

    init() {
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
                self.alertService.present(message: error.localizedDescription)
            }
            self.credential = try? snapshot?.data(as: Beeminder.Credential.self)
        }
        .store(in: &listeners)
    }

    func saveCredential(_ credential: Beeminder.Credential, user: User) {
        user.credentialDocument
            .setData(from: credential)
            .errorHandled(by: alertService)
    }

    func saveCredential(_ credential: Beeminder.Credential) {
        saveCredential(credential, user: user)
    }

    func removeCredential(user: User) {
        user.credentialDocument
            .delete()
            .errorHandled(by: alertService)
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
