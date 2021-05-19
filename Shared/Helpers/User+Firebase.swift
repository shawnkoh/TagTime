//
//  User+Firebase.swift
//  TagTime
//
//  Created by Shawn Koh on 19/5/21.
//

import Foundation
import Firebase

extension User {
    var userDocument: DocumentReference {
        Firestore.firestore().collection("users").document(id)
    }
}
