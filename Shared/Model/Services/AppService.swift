//
//  AppService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 17/4/21.
//

import Foundation
import Combine

final class AppService: ObservableObject {
    static let shared = AppService()

    @Published var isAuthenticated = false

    private var userSubscriber: AnyCancellable!

    init() {
        userSubscriber = AuthenticationService.shared.$user
            .receive(on: DispatchQueue.main)
            .sink { self.isAuthenticated = $0 != nil }
    }
}
