//
//  FacebookLoginService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 23/4/21.
//

import Foundation
import FBSDKLoginKit
import FirebaseAuth
import Combine

final class FacebookLoginService {
    static let shared = FacebookLoginService(authenticationService: AuthenticationService.shared)

    private let authenticationService: AuthenticationService

    init(authenticationService: AuthenticationService) {
        self.authenticationService = authenticationService
    }

    let loginManager = LoginManager()

    func login() {
        // TODO: add extension to return publisher
        loginManager.logIn(permissions: ["public_profile", "email"], from: nil) { result, error in
            if let error = error {
                AlertService.shared.present(message: error.localizedDescription)
            }
            guard
                result != nil,
                let accessToken = AccessToken.current
            else {
                return
            }
            let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
            self.authenticationService.link(with: credential)
                .tryCatch { error -> AnyPublisher<Void, Error> in
                    switch error {
                    case let AuthError.authError(error, code):
                        if code == .credentialAlreadyInUse {
                            return self.authenticationService.signIn(with: credential)
                                .map { _ in }
                                .eraseToAnyPublisher()
                        } else {
                            throw error
                        }
                    default:
                        throw error
                    }
                }
                .errorHandled(by: AlertService.shared)
        }
    }
}
