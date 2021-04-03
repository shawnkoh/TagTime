//
//  Settings.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/4/21.
//

import Foundation

class Settings: ObservableObject {
    @Published var pingInterval: Int

    @Published var beeminderAuthToken: String?
    // Initial state of the random number generator
    @Published var seed = 11193462
    // Ur-ping ie the birth of Timepie/TagTime! (unixtime)
    let urping = 1184097393


    init(pingInterval: Int = 45, beeminderAuthToken: String? = nil) {
        self.pingInterval = pingInterval
        self.beeminderAuthToken = beeminderAuthToken
    }
}
