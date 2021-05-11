//
//  AlertService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 12/4/21.
//

import Foundation
import os
import Combine

final class AlertService {
    @Published var isPresented = false
    @Published private(set) var message = ""

    var subscribers = Set<AnyCancellable>()

    // TODO: This should connect to somewhere like Sentry
    // TODO: Explore Apple's Logger mechanism

    func present(message: String) {
        log(message)
        self.message = message
        isPresented = true
    }

    func log(_ message: String) {
        Logger().critical("\(message, privacy: .public)")
    }

    func dismiss() {
        isPresented = false
        message = ""
    }
}

extension Publisher where Failure: Error {
    func errorHandled(by service: AlertService) {
        self.sink(receiveCompletion: { completion in
            switch completion {
            case let .failure(error):
                service.present(message: error.localizedDescription)
            case .finished:
                ()
            }
        }, receiveValue: { _ in })
        .store(in: &service.subscribers)
    }
}
