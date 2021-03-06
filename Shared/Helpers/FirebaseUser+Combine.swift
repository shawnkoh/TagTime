//
//  FirebaseUser+Combine.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 1/5/21.
//

import Foundation
import Combine
import Firebase

extension Firebase.User {
    func link(with credential: AuthCredential) -> Future<AuthDataResult, Error> {
        Future { promise in
            self.link(with: credential) { result, error in
                if let error = error  {
                    if let error = error as NSError?, let code = AuthErrorCode(rawValue: error.code) {
                        promise(.failure(AuthError.authError(error, code)))
                    } else {
                        promise(.failure(error))
                    }
                } else if let result = result {
                    promise(.success(result))
                } else {
                    promise(.failure(AuthError.noResult))
                }
            }
        }
    }

    func unlink(from provider: AuthProvider) -> Future<Firebase.User, Error> {
        Future { promise in
            self.unlink(fromProvider: provider.rawValue) { user, error in
                if let error = error {
                    promise(.failure(error))
                } else if let user = user {
                    promise(.success(user))
                } else {
                    promise(.failure(AuthError.noResult))
                }
            }
        }
    }
}
