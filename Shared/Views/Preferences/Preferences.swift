//
//  Preferences.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import SwiftUI

struct Preferences: View {
    @EnvironmentObject var store: Store
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

                if debugMode {
                    Divider()

                    Text("Debug Mode")
                        .font(.title)
                        .bold()

                    Text("Schedule notification in 7 seconds")
                        .bold()

                    Button(action: {
                        store.notificationService.scheduleNotification(ping: .init(timeIntervalSinceNow: 7))
                    }) {
                        HStack {
                            Spacer()
                            Text("SCHEDULE")
                                .foregroundColor(.primary)
                                .padding()
                            Spacer()
                        }
                        .background(Color.hsb(223, 69, 90))
                        .cornerRadius(8)
                    }
                }
            }

            Spacer()
        }
    }
}

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        Preferences()
            .environmentObject(SettingService.shared)
            .environmentObject(Stub.store)
    }
}
