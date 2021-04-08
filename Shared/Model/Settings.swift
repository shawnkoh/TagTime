//
//  Settings.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/4/21.
//

import Foundation

final class Settings: ObservableObject {
    // Average gap between pings, in minutes
    @Published var pingInterval: Int
    // Initial state of the random number generator
    @Published var seed: Int
    @Published var beeminderAuthToken: String?

    init(pingInterval: Int = 45, seed: Int = 11193462, beeminderAuthToken: String? = nil) {
        self.pingInterval = pingInterval
        self.seed = seed
        self.beeminderAuthToken = beeminderAuthToken
    }
}
