//
//  BeeminderLoginButton.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/5/21.
//

import SwiftUI
import AuthenticationServices
import BetterSafariView

struct BeeminderLoginButton: View {
    @EnvironmentObject var beeminderCredentialService: BeeminderCredentialService

    @State private var isAuthenticatingBeeminder = false

    let beeminder = "https://www.beeminder.com/apps/authorize"
    let clientId = "bq1o00l7savc1vtc2z9rsa4sq"
    let redirectUri = "tagtime://"
    let responseType = "token"

    var url: URL {
        .init(string: "\(beeminder)?client_id=\(clientId)&redirect_uri=\(redirectUri)&response_type=\(responseType)")!
    }

    var body: some View {
        if beeminderCredentialService.credential == nil {
            Card(text: "Login with Beeminder")
                .onPress { isAuthenticatingBeeminder = true }
            .webAuthenticationSession(isPresented: $isAuthenticatingBeeminder) {
                WebAuthenticationSession(url: url, callbackURLScheme: "tagtime") { callbackUrl, error in
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
                    let credential = BeeminderCredential(username: username, accessToken: accessToken)
                    beeminderCredentialService.saveCredential(credential)
                }
                .prefersEphemeralWebBrowserSession(false)
            }
        } else {
            Card(text: "Logout from Beeminder")
                .onPress { beeminderCredentialService.removeCredential() }
        }
    }
}

struct BeeminderLoginButton_Previews: PreviewProvider {
    static var previews: some View {
        BeeminderLoginButton()
            .environmentObject(BeeminderCredentialService.shared)
    }
}
