//
//  Router.swift
//  TagTime
//
//  Created by Shawn Koh on 23/5/21.
//

import Foundation
import Combine

// Extremely naive implementation of a Router
// Ideally, should be something like react-router
// Note: Router is intentionally not an EnvironmentObject because of Swift's protocol limitations
final class Router {
    enum Page: Hashable {
        case missedPingList
        case logbook
        case goalList
        case statistics
        case preferences
    }

    @Published var currentPage: Page = .missedPingList
}
