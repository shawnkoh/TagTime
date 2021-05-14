//
//  User.swift
//  TagTime
//
//  Created by Shawn Koh on 7/4/21.
//

import Foundation
import Firebase

struct User: Identifiable, Codable, Equatable {
    let id: String
    let startDate: Date
    var providers: [AuthProvider]
    var updatedDate: Date

    init(id: String, startDate: Date = Date(), providers: [AuthProvider] = [], updatedDate: Date = Date()) {
        self.id = id
        self.startDate = startDate
        self.providers = providers
        self.updatedDate = updatedDate
    }
}

extension User {
    var userDocument: DocumentReference {
        Firestore.firestore().collection("users").document(id)
    }
}
