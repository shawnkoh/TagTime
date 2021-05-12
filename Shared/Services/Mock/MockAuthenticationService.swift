//
//  MockAuthenticationService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 12/5/21.
//

import Foundation
import Combine
// TODO: Ideally this should not import Firebase
import Firebase

final class MockAuthenticationService: AuthenticationService {
    @Published var authStatus: AuthStatus = .signedOut
    var authStatusPublisher: Published<AuthStatus>.Publisher { $authStatus }

    private static let mockUser = User(id: "mock", startDate: Date().addingTimeInterval(-60*60*48))

    @Published private(set) var user: User = .init(id: User.unauthenticatedUserId)
    var userPublisher: Published<User>.Publisher { $user }

    private var subscribers = Set<AnyCancellable>()

    init() {
        // SwiftUI previews do not call TagTimeApp.ContentView.onAppear
        // so AppViewModel never calls signInAndSetUser
        signIn()
            .sink(receiveCompletion: { completion in }, receiveValue: { user in
                self.user = user
            })
            .store(in: &subscribers)
    }

    func signIn() -> AnyPublisher<User, Error> {
        Just(Self.mockUser)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func signIn(with credential: AuthCredential) -> AnyPublisher<User, Error> {
        Just(Self.mockUser)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func link(with credential: AuthCredential) -> AnyPublisher<Void, Error> {
        Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func signOut() {
        user = .init(id: User.unauthenticatedUserId)
    }

    func resetUserStartDate() {
        let date = Date()
        user = .init(id: user.id, startDate: date, updatedDate: date)
    }
}
