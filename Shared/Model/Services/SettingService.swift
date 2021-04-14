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
    @Published var beeminderAuthToken: String?

    init(averagePingInterval: Int = 45, beeminderAuthToken: String? = nil) {
        self.averagePingInterval = averagePingInterval
        self.beeminderAuthToken = beeminderAuthToken
    }
}
