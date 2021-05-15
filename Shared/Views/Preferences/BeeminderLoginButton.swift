//
//  BeeminderLoginButton.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/5/21.
//

import SwiftUI
import AuthenticationServices
import BetterSafariView
import Beeminder
import Resolver
import Combine

final class BeeminderLoginButtonViewModel: ObservableObject {
    @LazyInjected private var beeminderCredentialService: BeeminderCredentialService

    @Published private(set) var isAuthenticated = false
    private var subscribers = Set<AnyCancellable>()

    private let beeminder = "https://www.beeminder.com/apps/authorize"
    private let clientId = "bq1o00l7savc1vtc2z9rsa4sq"
    private let redirectUri = "tagtime://"
    private let responseType = "token"

    var url: URL {
        .init(string: "\(beeminder)?client_id=\(clientId)&redirect_uri=\(redirectUri)&response_type=\(responseType)")!
    }

    init() {
        beeminderCredentialService.credentialPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isAuthenticated = $0 != nil}
            .store(in: &subscribers)
    }

    func saveCredential(_ credential: Beeminder.Credential) {
        beeminderCredentialService.saveCredential(credential)
    }

    func removeCredential() {
        beeminderCredentialService.removeCredential()
    }
}

struct BeeminderLoginButton: View {
    @StateObject private var viewModel = BeeminderLoginButtonViewModel()
    @State private var isAuthenticatingBeeminder = false

    var body: some View {
        if viewModel.isAuthenticated {
            Text("Logout from Beeminder")
                .onTap { viewModel.removeCredential() }
                .cardButtonStyle(.baseCard)
        } else {
            Text("Login with Beeminder")
                .onTap { isAuthenticatingBeeminder = true }
                .cardButtonStyle(.baseCard)
                .webAuthenticationSession(isPresented: $isAuthenticatingBeeminder) {
                    WebAuthenticationSession(url: viewModel.url, callbackURLScheme: "tagtime") { callbackUrl, error in
                        if let error = error {
                            print(error)
                        }
                        guard
                            let callbackUrl = callbackUrl,
                            let queryItems = URLComponents(string: callbackUrl.absoluteString)?.queryItems,
                            let accessToken = queryItems.first(where: { $0.name == "access_token" })?.value,
                            let username = queryItems.first(where: { $0.name == "username" })?.value
                        else {
                            return
                        }
                        let credential = Beeminder.Credential(username: username, accessToken: accessToken)
                        viewModel.saveCredential(credential)
                    }
                    .prefersEphemeralWebBrowserSession(false)
                }
        }
    }
}

struct BeeminderLoginButton_Previews: PreviewProvider {
    static var previews: some View {
        #if DEBUG
        Resolver.root = .mock
        #endif
        return BeeminderLoginButton()
    }
}
