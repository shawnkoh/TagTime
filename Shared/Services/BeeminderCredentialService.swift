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

final class BeeminderCredentialService: ObservableObject {
    static let shared = BeeminderCredentialService()

    @Published private(set) var credential: BeeminderCredential?

    private var userSubscriber: AnyCancellable!
    private var subscribers = Set<AnyCancellable>()
    private var listeners = [ListenerRegistration]()

    init() {
        userSubscriber = AuthenticationService.shared.$user
            .sink { self.setup(user: $0) }
    }

    func setup(user: User?) {
        subscribers.forEach { $0.cancel() }
        subscribers = []
        listeners.forEach { $0.remove() }
        listeners = []
        guard let user = user else {
            self.credential = nil
            return
        }
        user.credentialDocument.addSnapshotListener { snapshot, error in
            if let error = error {
                AlertService.shared.present(message: error.localizedDescription)
            }
            let credential = try? snapshot?.data(as: BeeminderCredential.self)
            self.credential = credential
        }
        .store(in: &listeners)
    }

    func saveCredential(_ credential: BeeminderCredential, user: User) {
        user.credentialDocument
            .setData(from: credential)
            .errorHandled(by: AlertService.shared)
    }

    func saveCredential(_ credential: BeeminderCredential) {
        guard let user = AuthenticationService.shared.user else {
            return
        }
        saveCredential(credential, user: user)
    }

    func removeCredential(user: User) {
        user.credentialDocument
            .delete()
            .errorHandled(by: AlertService.shared)
    }

    func removeCredential() {
        guard let user = AuthenticationService.shared.user else {
            return
        }
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
