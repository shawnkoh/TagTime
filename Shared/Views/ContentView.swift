//
//  ContentView.swift
//  Shared
//
//  Created by Shawn Koh on 31/3/21.
//

import SwiftUI
import Firebase
import Resolver
import Combine

final class ContentViewModel: ObservableObject {
    @Injected private var authenticationService: AuthenticationService

    private var subscribers = Set<AnyCancellable>()

    @Published private(set) var isAuthenticated = false

    init() {
        authenticationService.authStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { authStatus in
                switch authStatus {
                case .anonymous, .signedIn:
                    self.isAuthenticated = true
                case .signedOut:
                    self.isAuthenticated = false
                }
            }
            .store(in: &subscribers)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        if viewModel.isAuthenticated {
            AuthenticatedView()
        } else {
            UnauthenticatedView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        #if DEBUG
        Resolver.root = .mock
        #endif
        return ContentView()
            .preferredColorScheme(.dark)
    }
}
