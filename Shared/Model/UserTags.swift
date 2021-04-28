//
//  UserTags.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 28/4/21.
//

import Foundation

struct UserTags: Codable {
    var tags: [Tag: Tag]
    
    init(tags: [Tag: Tag] = [:]) {
        self.tags = tags
    }
}
