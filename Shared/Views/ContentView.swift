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
        authenticationService.$user
            .map { $0.id != AuthenticationService.unauthenticatedUserId }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isAuthenticated = $0 }
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
        ContentView()
            .preferredColorScheme(.dark)
    }
}
