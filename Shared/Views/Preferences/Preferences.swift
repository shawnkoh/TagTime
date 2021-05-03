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

    @State private var isAuthenticatingBeeminder = false

    @ViewBuilder
    private func button(text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(text)
                    .foregroundColor(.primary)
                    .padding()
                Spacer()
            }
            .background(Color.hsb(223, 69, 98))
            .cornerRadius(8)
        }
    }

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

                button(text: "Login with Facebook") { FacebookLoginService.shared.login() }

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
