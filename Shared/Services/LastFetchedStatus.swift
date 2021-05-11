//
//  LastFetchedStatus.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 11/5/21.
//

import Foundation

enum LastFetchedStatus: Equatable {
    case loading
    case lastFetched(Date)
}
