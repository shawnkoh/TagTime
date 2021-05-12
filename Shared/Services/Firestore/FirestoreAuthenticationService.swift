//
//  FirestoreAuthenticationService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 12/5/21.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import Resolver
import Combine

public final class FirestoreAuthenticationService: AuthenticationService {
    @Injected private var alertService: AlertService

    @Published fileprivate(set) var user = User(id: User.unauthenticatedUserId, startDate: Date())
    var userPublisher: Published<User>.Publisher { $user }

    public var isAuthenticated: Bool {
        user.id != User.unauthenticatedUserId
    }

    public init() {}

    func signIn() -> AnyPublisher<User, Error> {
        if let currentUser = Auth.auth().currentUser {
            return getUser(id: currentUser.uid)
                .flatMap { user -> AnyPublisher<User, Error> in
                    if let user = user {
                        return Just(user).setFailureType(to: Error.self).eraseToAnyPublisher()
                    } else {
                        return self.makeUser(id: currentUser.uid)
                    }
                }
                .eraseToAnyPublisher()
        } else {
            return Auth.auth().signInAnonymously()
                .flatMap { result -> AnyPublisher<User, Error> in
                    self.makeUser(id: result.user.uid)
                }
                .eraseToAnyPublisher()
        }
    }

    func signInAndSetUser() -> AnyPublisher<User, Error> {
        signIn()
            .map { user in
                self.user = user
                return user
            }
            .eraseToAnyPublisher()
    }

    func signIn(with credential: AuthCredential) -> AnyPublisher<User, Error> {
        Auth.auth().signIn(with: credential)
            .flatMap { result -> AnyPublisher<User, Error> in
                self.getUser(id: result.user.uid)
                    .flatMap { user -> AnyPublisher<User, Error> in
                        if let user = user {
                            return Just(user).setFailureType(to: Error.self).eraseToAnyPublisher()
                        } else {
                            return self.makeUser(id: result.user.uid).eraseToAnyPublisher()
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func link(with credential: AuthCredential) -> AnyPublisher<Void, Error> {
        guard let currentUser = Auth.auth().currentUser else {
            return Fail(error: AuthError.notAuthenticated).eraseToAnyPublisher()
        }

        return currentUser.link(with: credential)
            // TODO: flatMap to update User document e.g. to get email address
            .map { _ in }
            .eraseToAnyPublisher()
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            user = User(id: User.unauthenticatedUserId, startDate: Date())
        } catch {
            alertService.present(message: error.localizedDescription)
        }
    }

    private func makeUser(id: String) -> AnyPublisher<User, Error> {
        let user = User(id: id, startDate: Date())
        return Firestore.firestore().collection("users").document(user.id).setData(from: user)
            .map { user }
            .eraseToAnyPublisher()
    }


    private func getUser(id: String) -> Future<User?, Error> {
        Future { promise in
            Firestore.firestore().collection("users").document(id)
                .getDocument() { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                    } else if let snapshot = snapshot, snapshot.exists {
                        promise(.success(try? snapshot.data(as: User.self)))
                    } else {
                        promise(.failure(AuthError.noSnapshot))
                    }
                }
        }
    }
}

#if DEBUG
extension FirestoreAuthenticationService {
    func resetUserStartDate() {
        let newUser = User(id: user.id, startDate: Date())
        do {
            try Firestore.firestore().collection("users").document(user.id).setData(from: newUser) { error in
                if let error = error {
                    self.alertService.present(message: error.localizedDescription)
                } else {
                    self.user = newUser
                }
            }
        } catch {
            alertService.present(message: error.localizedDescription)
        }
    }
}
#endif