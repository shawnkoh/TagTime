//
//  Ping.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import Foundation

typealias Ping = Date

extension Ping {
    var documentId: String {
        timeIntervalSince1970.description
    }
}
