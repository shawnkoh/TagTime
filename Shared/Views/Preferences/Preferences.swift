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
    #if os(iOS)
    @Injected private var facebookLoginService: FacebookLoginService
    #endif
    @Injected private var authenticationService: AuthenticationService
    @Injected private var alertService: AlertService

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

    #if os(iOS)
    func loginWithFacebook() {
        facebookLoginService.login()
    }
    #endif

    func logoutFromFacebook() {
        authenticationService.unlink(from: .facebook)
            .errorHandled(by: alertService)
    }
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

                #if os(iOS)
                if viewModel.isLoggedIntoFacebook {
                    Text("Logout from Facebook")
                        .onTap { viewModel.logoutFromFacebook() }
                } else {
                    Text("Login with Facebook")
                        .onTap { viewModel.loginWithFacebook() }
                }
                #endif

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
