//
//  User.swift
//  TagTime
//
//  Created by Shawn Koh on 7/4/21.
//

import Foundation
import Firebase

struct User: Identifiable, Codable {
    let id: String
    let startDate: Date

    init(id: String, startDate: Date = Date()) {
        self.id = id
        self.startDate = startDate
    }
}

extension User {
    var userDocument: DocumentReference {
        Firestore.firestore().collection("users").document(id)
    }

    var answerCollection: CollectionReference {
        userDocument.collection("answers")
    }
}
