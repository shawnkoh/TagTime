//
//  AuthenticationService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 14/4/21.
//

import Foundation
import Combine
// TODO: Ideally, this should not import Firebase
import Firebase

enum AuthError: Error {
    case noResult
    case authError(Error, AuthErrorCode)
    case notAuthenticated
    case noSnapshot
}

extension User {
    static let unauthenticatedUserId = "unauthenticated"

    var isAuthenticated: Bool {
        id != Self.unauthenticatedUserId
    }
}

enum Providers: String {
    case facebook = "facebook.com"
    case apple = "apple.com"
}

enum AuthStatus: Equatable {
    case anonymous(String)
    case signedIn(String, [Providers])
    case signedOut
}

protocol AuthenticationService {
    var user: User { get }
    var userPublisher: Published<User>.Publisher { get }
    var authStatus: AuthStatus { get }
    var authStatusPublisher: Published<AuthStatus>.Publisher { get }

    func signIn() -> AnyPublisher<User, Error>
    func signIn(with credential: AuthCredential) -> AnyPublisher<User, Error>
    func link(with credential: AuthCredential) -> AnyPublisher<Void, Error>
    func signOut()

    #if DEBUG
    func resetUserStartDate()
    #endif
}
