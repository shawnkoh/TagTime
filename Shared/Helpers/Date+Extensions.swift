//
//  Date+Extensions.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 14/4/21.
//

import Foundation

public extension Date {
    var documentId: String {
        timeIntervalSince1970.description
    }
}
