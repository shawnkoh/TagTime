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

protocol AuthenticationService {
    var user: User { get }
    var userPublisher: Published<User>.Publisher { get }

    func signIn() -> AnyPublisher<User, Error>
    // TODO: Not sure if we should have a signInAndSetUser method. Workaround to allow this protocol
    func signInAndSetUser() -> AnyPublisher<User, Error>
    func signIn(with credential: AuthCredential) -> AnyPublisher<User, Error>
    func link(with credential: AuthCredential) -> AnyPublisher<Void, Error>
    func signOut()

    #if DEBUG
    func resetUserStartDate()
    #endif
}
