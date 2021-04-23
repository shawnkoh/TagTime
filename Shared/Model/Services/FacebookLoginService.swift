//
//  FacebookLoginService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 23/4/21.
//

import Foundation
import FBSDKLoginKit
import FirebaseAuth

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
                let accessToken = AccessToken.current,
                let user = Auth.auth().currentUser
            else {
                return
            }
            let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
            user.link(with: credential) { result, error in
                if let error = error {
                    AlertService.shared.present(message: error.localizedDescription)
                }
            }
        }
    }
}
