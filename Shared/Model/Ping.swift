//
//  Ping.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import Foundation

public typealias Ping = Date

public extension Ping {
    var documentId: String {
        timeIntervalSince1970.description
    }
}
