//
//  AlertService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 12/4/21.
//

import Foundation
import os

final class AlertService: ObservableObject {
    @Published var isPresented = false
    @Published private(set) var message = ""

    static let shared = AlertService()

    // TODO: This should connect to somewhere like Sentry
    // TODO: Explore Apple's Logger mechanism

    func present(message: String) {
        Logger().critical("\(message, privacy: .public)")
        self.message = message
        isPresented = true
    }

    func dismiss() {
        isPresented = false
        message = ""
    }
}
