//
//  Auth+Combine.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 1/5/21.
//

import Foundation
import Combine
import Firebase

extension Auth {
    func signInAnonymously() -> Future<AuthDataResult, Error> {
        Future { promise in
            self.signInAnonymously() { result, error in
                if let error = error {
                    promise(.failure(error))
                } else if let result = result {
                    promise(.success(result))
                } else {
                    promise(.failure(AuthError.noResult))
                }
            }
        }
    }

    func signIn(with credential: AuthCredential) -> Future<AuthDataResult, Error> {
        Future { promise in
            self.signIn(with: credential) { result, error in
                if let error = error {
                    promise(.failure(error))
                } else if let result = result {
                    promise(.success(result))
                } else {
                    promise(.failure(AuthError.noResult))
                }
            }
        }
    }
}

extension Publisher where Output == User {
    /// For use in the various services. updatedDate and providers are intentionally ignored to prevent the services from reinitialising again
    func removeDuplicatesForServices() -> Publishers.RemoveDuplicates<Self> {
        removeDuplicates(by: { $0.id == $1.id && $0.startDate == $1.startDate })
    }
}
