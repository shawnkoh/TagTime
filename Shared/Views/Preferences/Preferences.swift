//
//  Preferences.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import SwiftUI
import Resolver
import Combine

final class PreferencesViewModel: ObservableObject {
    @Injected private var settingService: SettingService
    @Injected private var facebookLoginService: FacebookLoginService
    @Injected private var authenticationService: AuthenticationService

    @Published private(set) var isLoggedIntoFacebook = false
    @Published var averagePingInterval: Int = 45

    private var subscribers = Set<AnyCancellable>()

    init() {
        authenticationService.authStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink {
                switch $0 {
                case let .signedIn(_, providers):
                    self.isLoggedIntoFacebook = providers.contains(.facebook)
                default:
                    self.isLoggedIntoFacebook = false
                }
            }
            .store(in: &subscribers)

        settingService.$averagePingInterval
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.averagePingInterval = $0 }
            .store(in: &subscribers)
    }

    func loginWithFacebook() {
        facebookLoginService.login()
    }

    func logoutFromFacebook() {}
}

struct Preferences: View {
    @StateObject private var viewModel = PreferencesViewModel()

    #if DEBUG
    @State private var isDebugPresented = false
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PageTitle(title: "Preferences", subtitle: "Suit yourself")

            VStack(alignment: .leading) {
                Text("Ping Interval (minutes)")
                    .bold()

                TextField(
                    "Ping Interval",
                    value: $viewModel.averagePingInterval,
                    formatter: NumberFormatter(),
                    onEditingChanged: { _ in },
                    onCommit: {}
                )

                BeeminderLoginButton()

                if viewModel.isLoggedIntoFacebook {
                    Text("Login with Facebook")
                        .onTap { viewModel.loginWithFacebook() }
                } else {
                    Text("Logout from Facebook")
                        .onTap { viewModel.logoutFromFacebook() }
                }

                #if DEBUG
                Text("Open Debug Menu")
                    .onTap { isDebugPresented = true }
                    .sheet(isPresented: $isDebugPresented) {
                        DebugMenu()
                    }
                #endif
            }
            Spacer()
        }
        .cardButtonStyle(.baseCard)
    }
}

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        #if DEBUG
        Resolver.root = .mock
        #endif
        return Preferences()
    }
}
