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
import AuthenticationServices

public final class FirestoreAuthenticationService: AuthenticationService {
    @LazyInjected private var appleLoginService: AppleLoginService
    @LazyInjected private var alertService: AlertService

    // TODO: I think AuthStatus can be hidden
    // It's mostly a User implementation detail.
    @Published private(set) var authStatus: AuthStatus = .loading
    var authStatusPublisher: Published<AuthStatus>.Publisher { $authStatus }

    @Published fileprivate(set) var user = User(id: User.unauthenticatedUserId, startDate: Date())
    var userPublisher: Published<User>.Publisher { $user }

    public var isAuthenticated: Bool {
        user.id != User.unauthenticatedUserId
    }

    private var authHandle: AuthStateDidChangeListenerHandle?
    private var subscribers = Set<AnyCancellable>()
    private var listeners = [ListenerRegistration]()

    private let auth = Auth.auth()

    public init() {
        // I believe that attaching listener here makes it a lot faster to start up the app
        // compared to using View.onAppear
        attachListeners()
    }

    // This helps to prevent AuthenticationService from listening unnecessarily.
    // This is useful for NotificationHandler, especially when the app is in the background
    // TODO: Ideally, a View should call this function.
    func attachListeners() {
        // We are only interested in whether user.uid changes.
        // All other data about currentUser is unreliable because it is 100% locally held. It does not sync between devices.
        authHandle = auth.addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.authStatus = .signedIn(user.uid)
            } else {
                self?.authStatus = .signedOut
            }
        }

        // Create an anonymous account when the user signs out
        // TODO: This might be changed depending on the onboarding workflow
        $authStatus
            .removeDuplicates()
            .filter { $0 == .signedOut }
            .flatMap { authStatus -> AnyPublisher<Void, Error> in
                self.auth.signInAnonymously()
                    .map { _ in }
                    .eraseToAnyPublisher()
            }
            .ignoreOutput()
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    self.alertService.present(message: error.localizedDescription)
                case .finished:
                    ()
                }
            }, receiveValue: { _ in
                // Will never receive value
            })
            .store(in: &subscribers)


        $authStatus
            .removeDuplicates()
            .filter { $0 != .loading && $0 != .signedOut }
            .tryMap { authStatus -> String in
                switch authStatus {
                case let .signedIn(uid):
                    return uid
                default:
                    throw AuthError.notAuthenticated
                }
            }
            .flatMap { uid -> AnyPublisher<User, Error> in
                self.getOrMakeUser(uid: uid)
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    self.alertService.present(message: error.localizedDescription)
                case .finished:
                    ()
                }
            }, receiveValue: { [weak self] user in
                self?.setupUserSnapshotListener(userId: user.id)
            })
            .store(in: &subscribers)
    }

    private func setupUserSnapshotListener(userId: String) {
        listeners.forEach { $0.remove() }
        listeners = []
        Firestore.firestore().collection("users").document(userId).addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                self?.alertService.present(message: error.localizedDescription)
            }

            guard let snapshot = snapshot, let user = try? snapshot.data(as: User.self) else {
                return
            }

            self?.user = user
        }
        .store(in: &listeners)
    }

    func signIn() -> AnyPublisher<User, Error> {
        if let currentUser = auth.currentUser {
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
            return auth.signInAnonymously()
                .flatMap { result -> AnyPublisher<User, Error> in
                    self.makeUser(id: result.user.uid)
                }
                .eraseToAnyPublisher()
        }
    }

    func signIn(with credential: AuthCredential) -> AnyPublisher<Void, Error> {
        auth.signIn(with: credential)
            .map { _ in }
            .eraseToAnyPublisher()
    }

    func link(with credential: AuthCredential) -> AnyPublisher<Void, Error> {
        guard
            user.id != User.unauthenticatedUserId,
            let currentUser = auth.currentUser,
            let provider = AuthProvider(rawValue: credential.provider)
        else {
            return Fail(error: AuthError.notAuthenticated).eraseToAnyPublisher()
        }

        return currentUser.link(with: credential)
            // TODO: flatMap to update User document e.g. to get email address
            // TODO: Need to record user's email address here because we can only get the user's email address the
            // very first time he signs in with Apple.
            .flatMap { result -> AnyPublisher<Void, Error> in
                var providerSet = Set(self.user.providers)
                providerSet.insert(provider)
                let providers = Array(providerSet).sorted { $0.rawValue < $1.rawValue }
                let user = User(id: result.user.uid, startDate: self.user.startDate, providers: providers, updatedDate: Date())
                return Firestore.firestore()
                    .collection("users")
                    .document(user.id)
                    .setData(from: user).eraseToAnyPublisher()
            }
            .map { _ in }
            .eraseToAnyPublisher()
    }

    func unlink(from provider: AuthProvider) -> AnyPublisher<Void, Error> {
        guard
            user.id != User.unauthenticatedUserId,
            let currentUser = auth.currentUser
        else {
            return Fail(error: AuthError.notAuthenticated).eraseToAnyPublisher()
        }

        return currentUser
            .unlink(from: provider)
            .flatMap { user -> AnyPublisher<Void, Error> in
                let uid = user.uid
                var providerSet = Set(self.user.providers)
                providerSet.remove(provider)
                let providers = Array(providerSet).sorted { $0.rawValue < $1.rawValue }
                let user = User(id: uid, startDate: self.user.startDate, providers: providers, updatedDate: Date())

                return Firestore.firestore()
                    .collection("users")
                    .document(uid)
                    .setData(from: user).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func signOut() {
        do {
            try auth.signOut()
            user = User(id: User.unauthenticatedUserId, startDate: Date())
        } catch {
            alertService.present(message: error.localizedDescription)
        }
    }

    func linkWithApple(authorization: ASAuthorization) -> AnyPublisher<Void, Error> {
        do {
            let credential = try getCredential(from: authorization)
            return link(with: credential)
            // TODO: Need to send email address specifically for Apple because it's only sent the first time the account was linked
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    private func getCredential(from authorization: ASAuthorization) throws -> OAuthCredential {
        guard
            let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let nonce = appleLoginService.currentNonce,
            let appleIDToken = appleIDCredential.identityToken,
            let idTokenString = String(data: appleIDToken, encoding: .utf8)
        else {
            throw AuthError.failedToGetCredential
        }
        // Initialize a Firebase credential.
        return OAuthProvider.credential(withProviderID: AuthProvider.apple.rawValue, idToken: idTokenString, rawNonce: nonce)
    }

    private func makeUser(id: String) -> AnyPublisher<User, Error> {
        guard id != User.unauthenticatedUserId else {
            return Fail(error: AuthError.notAuthenticated).eraseToAnyPublisher()
        }
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
                        promise(.success(nil))
                    }
                }
        }
    }

    private func getOrMakeUser(uid: String) -> AnyPublisher<User, Error> {
        getUser(id: uid)
            .flatMap { user -> AnyPublisher<User, Error> in
                if let user = user {
                    return Just(user).setFailureType(to: Error.self).eraseToAnyPublisher()
                } else {
                    return self.makeUser(id: uid)
                }
            }
            .eraseToAnyPublisher()
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
