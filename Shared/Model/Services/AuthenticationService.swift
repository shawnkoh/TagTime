//
//  AuthenticationService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 14/4/21.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

final class AuthenticationService: ObservableObject {
    @Published private(set) var user: User?

    init() {
        if let user = Auth.auth().currentUser {
            getUser(id: user.uid)
        } else {
            signInAnonymously()
        }
    }

    private func setupUser(id: String) {
        let user = User(id: id, startDate: Date())
        do {
            try Firestore.firestore()
                .collection("users")
                .document(user.id)
                .setData(from: user) { error in
                    if let error = error {
                        print(error)
                    } else {
                        self.user = user
                    }
                }
        } catch {
            // TODO: Handle this
            print("Unable to save user", user)
        }
    }

    private func getUser(id: String) {
        Firestore.firestore()
            .collection("users")
            .document(id)
            .getDocument() { [self] (snapshot, error) in
                do {
                    guard let user = try snapshot?.data(as: User.self) else {
                        setupUser(id: id)
                        return
                    }
                    self.user = user
                } catch {
                    // TODO: Handle this
                    print("Unable to get user")
                }
            }
    }

    private func signInAnonymously() {
        Auth.auth().signInAnonymously() { [self] (result, error) in
            guard let result = result else {
                // TODO: Find a way to display this
                print("unable to sign in anonymously", error?.localizedDescription as Any)
                return
            }
            setupUser(id: result.user.uid)
        }
    }
}
