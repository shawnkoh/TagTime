//
//  RealFirebaseService.swift
//  TagTime
//
//  Created by Shawn Koh on 15/5/21.
//

import Foundation
import Firebase
import FirebaseFirestore

final class RealFirebaseService: FirebaseService {
    func configure() {
        FirebaseApp.configure()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        Firestore.firestore().settings = settings
    }
}
