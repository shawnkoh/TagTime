//
//  FacebookLoginService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 23/4/21.
//

#if os(iOS)
import Foundation
import FBSDKLoginKit
import FirebaseAuth
import Combine
import Resolver

final class FacebookLoginService {
    @LazyInjected private var authenticationService: AuthenticationService
    @LazyInjected private var alertService: AlertService

    let loginManager = LoginManager()

    func login() {
        // TODO: add extension to return publisher
        loginManager.logIn(permissions: ["public_profile", "email"], from: nil) { result, error in
            if let error = error {
                self.alertService.present(message: error.localizedDescription)
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
                .errorHandled(by: self.alertService)
        }
    }
}
#endif
