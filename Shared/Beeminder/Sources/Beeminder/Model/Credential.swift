//
//  Credential.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/5/21.
//

import Foundation

public struct Credential: Codable {
    public let username: String
    public let accessToken: String
    public let updatedDate: Date

    public init(username: String, accessToken: String, updatedDate: Date = Date()) {
        self.username = username
        self.accessToken = accessToken
        self.updatedDate = updatedDate
    }
}
