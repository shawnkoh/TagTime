//
//  ContentView.swift
//  Shared
//
//  Created by Shawn Koh on 31/3/21.
//

import SwiftUI
import Resolver
import Combine
import SwiftUIX

final class ContentViewModel: ObservableObject {
    @Injected private var authenticationService: AuthenticationService

    private var subscribers = Set<AnyCancellable>()

    @Published private(set) var isAuthenticated = false

    init() {
        authenticationService.userPublisher
            .removeDuplicatesForServices()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isAuthenticated = $0.isAuthenticated }
            .store(in: &subscribers)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        if viewModel.isAuthenticated {
            return AnyView(AuthenticatedView())
        } else {
            return AnyView(UnauthenticatedView())
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
