//
//  AlertConfig.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 12/4/21.
//

import Foundation

final class AlertConfig: ObservableObject {
    @Published var isPresented = false
    @Published private(set) var message = ""

    func present(message: String) {
        self.message = message
        isPresented = true
    }

    func dismiss() {
        isPresented = false
        message = ""
    }
}
