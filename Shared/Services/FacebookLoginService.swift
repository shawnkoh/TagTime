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
    static let shared = FacebookLoginService()

    let loginManager = LoginManager()

    func login() {
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
            AuthenticationService.shared.link(with: credential)
                .tryCatch { error -> AnyPublisher<Void, Error> in
                    switch error {
                    case let AuthError.authError(error, code):
                        if code == .credentialAlreadyInUse {
                            return AuthenticationService.shared.signIn(with: credential)
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
