//
//  Query+Combine.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 11/5/21.
//

import Foundation
import Combine
import Firebase

extension Query {
    enum Errors: Error {
        case noSnapshot
    }

    func getDocuments(source: FirestoreSource) -> Future<QuerySnapshot, Error> {
        Future { promise in
            self.getDocuments(source: source) { snapshot, error in
                if let error = error {
                    promise(.failure(error))
                }

                if let snapshot = snapshot {
                    promise(.success(snapshot))
                } else {
                    promise(.failure(Query.Errors.noSnapshot))
                }
            }
        }
    }
}
