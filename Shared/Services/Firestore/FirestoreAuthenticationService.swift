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
    @Injected private var appleLoginService: AppleLoginService
    @Injected private var alertService: AlertService

    @Published fileprivate(set) var user = User(id: User.unauthenticatedUserId, startDate: Date())
    var userPublisher: Published<User>.Publisher { $user }

    @Published private(set) var authStatus: AuthStatus = .loading
    var authStatusPublisher: Published<AuthStatus>.Publisher { $authStatus }

    public var isAuthenticated: Bool {
        user.id != User.unauthenticatedUserId
    }

    private var idTokenHandle: IDTokenDidChangeListenerHandle?
    private var subscribers = Set<AnyCancellable>()

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
        // TODO: We should not rely on this listener to update authStatus
        // Instead, we should observe Firestore directly to check if there are any updates to the user.
        // A complication arises with firestore security rules. Need to be careful there to allow us to observe and update the state accordingly.
        idTokenHandle = auth.addIDTokenDidChangeListener(authListener)

        $authStatus
            .filter { $0 != .loading }
            .tryMap { authStatus -> String? in
                switch authStatus {
                case let .anonymous(uid), let .signedIn(uid, _):
                    return uid
                case .signedOut:
                    return nil
                // This is basically an impossible scenario
                case .loading:
                    throw AuthError.notAuthenticated
                }
            }
            .removeDuplicates()
            .flatMap { [self] uid -> AnyPublisher<User, Error> in
                // so i suspect what is happening is that there is an order of operations going on. AuthStatus was not loaded yet.
                // we should have an explicit unknown status
                if let uid = uid {
                    return getOrMakeUser(uid: uid)
                } else {
                    return auth.signInAnonymously()
                        // ignore user because we rely on authListener to update $authStatus
                        // updating $authStatus will then trigger another call to update user
                        // TODO: There must be a better way to do this. maybe if we just rely on Onboarding to decide what to do this will get far simpler.
                        .map { _ in User(id: User.unauthenticatedUserId) }
                        .eraseToAnyPublisher()
                }
            }
            // ignore unauthenticated user when we call signInAnonymously
            // TODO: This obviously doesn't trigger
            // instead, rely on authListener to update authStatus
            .removeDuplicates()
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    self.alertService.present(message: error.localizedDescription)
                case .finished:
                    ()
                }
            }, receiveValue: { user in
                self.user = user
            })
            .store(in: &subscribers)
    }

    private func authListener(_ auth: Auth, _ user: Firebase.User?) -> Void {
        guard let user = user else {
            authStatus = .signedOut
            return
        }

        guard !user.isAnonymous else {
            authStatus = .anonymous(user.uid)
            return
        }

        let providers: [AuthProvider] = user.providerData.compactMap {
            switch $0.providerID {
            case AuthProvider.apple.rawValue:
                return .apple
            case AuthProvider.facebook.rawValue:
                return .facebook
            default:
                return nil
            }
        }
        authStatus = .signedIn(user.uid, providers)
    }

    func signInAnonymously() {
        auth.signInAnonymously()
            .errorHandled(by: alertService)
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
        guard let currentUser = auth.currentUser else {
            return Fail(error: AuthError.notAuthenticated).eraseToAnyPublisher()
        }

        return currentUser.link(with: credential)
            // TODO: flatMap to update User document e.g. to get email address
            // TODO: Need to record user's email address here because we can only get the user's email address the
            // very first time he signs in with Apple.
            .map { _ in }
            .eraseToAnyPublisher()
    }

    func unlink(from provider: AuthProvider) -> AnyPublisher<Void, Error> {
        guard let currentUser = auth.currentUser else {
            return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        return Future { promise in
            currentUser.unlink(fromProvider: provider.rawValue) { _, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
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
