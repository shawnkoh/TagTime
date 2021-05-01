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
import Combine

enum AuthError: Error {
    case noResult
    case authError(Error, AuthErrorCode)
    case notAuthenticated
    case noSnapshot
}

// AuthenticationService is intentionally not an ObservableObject
// Because it is not intended to be used directly by a View.
// Rather, it is a supporting service that helps the other services
final class AuthenticationService {
    enum AuthenticationError: Error {
        case couldNotSignInAnonymously
    }

    static let shared = AuthenticationService()

    @Published fileprivate(set) var user: User?

    init() {}

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
            user = nil
        } catch {
            AlertService.shared.present(message: error.localizedDescription)
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

extension AnyPublisher where Output == User, Failure == Error {
    func setUser(service: AuthenticationService) -> AnyPublisher<User, Error> {
        self.map { user -> User in
            service.user = user
            return user
        }
        .eraseToAnyPublisher()
    }
}

#if DEBUG
extension AuthenticationService {
    func resetUserStartDate() {
        guard let user = user else {
            return
        }
        let newUser = User(id: user.id, startDate: Date())
        do {
            try Firestore.firestore().collection("users").document(user.id).setData(from: newUser) { error in
                if let error = error {
                    AlertService.shared.present(message: error.localizedDescription)
                } else {
                    self.user = newUser
                }
            }
        } catch {
            AlertService.shared.present(message: error.localizedDescription)
        }
    }
}
#endif
