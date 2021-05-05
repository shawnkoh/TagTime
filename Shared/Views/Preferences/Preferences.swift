//
//  Preferences.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import SwiftUI

struct Preferences: View {
    @EnvironmentObject var settingService: SettingService

    private var debugMode = true

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
                    .onTap { FacebookLoginService.shared.login() }
                    .cardButtonStyle(.baseCard)

                #if DEBUG
                Divider()
                DebugMenu()
                #endif
            }

            Spacer()
        }
    }
}

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        Preferences()
            .environmentObject(SettingService.shared)
    }
}
