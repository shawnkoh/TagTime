//
//  Tag.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import Foundation

struct Tag: Identifiable, Hashable {
    let id: UUID
    let name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
