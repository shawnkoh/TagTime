//
//  OpenPingService.swift
//  TagTime
//
//  Created by Shawn Koh on 17/5/21.
//

import Foundation

final class OpenPingService {
    @Published private(set) var openedPing: Date?

    func openPing(_ ping: Date) {
        self.openedPing = ping
    }
}
