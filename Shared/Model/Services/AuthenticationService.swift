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

// AuthenticationService is intentionally not an ObservableObject
// Because it is not intended to be used directly by a View.
// Rather, it is a supporting service that helps the other services
final class AuthenticationService {
    enum AuthenticationError: Error {
        case couldNotSignInAnonymously
    }

    static let shared = AuthenticationService()

    @Published private(set) var user: User?

    init() {}

    func signIn() -> Result<User, Error> {
        getUserIdOrMakeOne()
            .flatMap(getUserOrMakeOne)
            .map { user in
                self.user = user
                return user
            }
    }

    private func getUserId() -> String? {
        Auth.auth().currentUser?.uid
    }

    private func getUserIdOrMakeOne() -> Result<String, Error> {
        if let uid = getUserId() {
            return .success(uid)
        }

        var result: Result<String, Error>!
        let semaphore = DispatchSemaphore(value: 0)
        Auth.auth().signInAnonymously() { (data, error) in
            if let uid = data?.user.uid {
                result = .success(uid)
            } else {
                result = .failure(AuthenticationError.couldNotSignInAnonymously)
            }
            semaphore.signal()
        }
        _ = semaphore.wait(wallTimeout: .distantFuture)

        return result
    }

    private func getUser(id: String) -> Result<User?, Error> {
        var result: Result<User?, Error>!

        let semaphore = DispatchSemaphore(value: 0)

        Firestore.firestore()
            .collection("users")
            .document(id)
            .getDocument() { (snapshot, error) in
                if let error = error {
                    result = .failure(error)
                    return
                }

                do {
                    result = .success(try snapshot?.data(as: User.self))
                } catch {
                    result = .failure(error)
                }

                semaphore.signal()
            }

        _ = semaphore.wait(wallTimeout: .distantFuture)

        return result
    }

    private func createUser(id: String) -> Result<User, Error> {
        let user = User(id: id)

        var result: Result<User, Error>!
        let semaphore = DispatchSemaphore(value: 0)
        do {
            try Firestore.firestore()
                .collection("users")
                .document(id)
                .setData(from: user) { error in
                    if let error = error {
                        result = .failure(error)
                    } else {
                        result = .success(user)
                    }
                    semaphore.signal()
                }
        } catch {
            result = .failure(error)
            semaphore.signal()
        }
        _ = semaphore.wait(wallTimeout: .distantFuture)
        return result
    }

    private func getUserOrMakeOne(id: String) -> Result<User, Error> {
        getUser(id: id)
            .flatMap { user in
                if let user = user {
                    return .success(user)
                } else {
                    return createUser(id: id)
                }
            }
    }
}
