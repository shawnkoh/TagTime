//
//  FacebookLoginService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 23/4/21.
//

import Foundation
import FBSDKLoginKit

final class FacebookLoginService: ObservableObject {
    static let shared = FacebookLoginService()

    let loginManager = LoginManager()

    func login() {
        loginManager.logIn(permissions: ["public_profile", "email"], from: nil) { result, error in
            if let error = error {

            }
            guard let result = result else {
                return
            }
            print(result)
        }
    }
}
