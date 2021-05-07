//
//  Preferences.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import SwiftUI

struct Preferences: View {
    @EnvironmentObject var settingService: SettingService
    @EnvironmentObject var facebookLoginService: FacebookLoginService

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
                    value: $settingService.averagePingInterval,
                    formatter: NumberFormatter(),
                    onEditingChanged: { _ in },
                    onCommit: {}
                )

                BeeminderLoginButton()

                Text("Login with Facebook")
                    .onTap { facebookLoginService.login() }

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
        Preferences()
            .environmentObject(SettingService.shared)
    }
}
