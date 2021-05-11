//
//  SettingService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/4/21.
//

import Foundation

final class SettingService: ObservableObject {
    // Average gap between pings, in minutes
    @Published var averagePingInterval: Int

    init(averagePingInterval: Int = 45) {
        self.averagePingInterval = averagePingInterval
    }
}
