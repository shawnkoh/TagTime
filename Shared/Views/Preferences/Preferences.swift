//
//  Preferences.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import SwiftUI

struct Preferences: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var store: Store

    private var debugMode = true

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PageTitle(title: "Preferences", subtitle: "Suit yourself")

            VStack(alignment: .leading) {
                Text("Ping Interval (minutes)")
                    .bold()

                TextField(
                    "Ping Interval",
                    value: $settings.averagePingInterval,
                    formatter: NumberFormatter(),
                    onEditingChanged: { _ in },
                    onCommit: {}
                )

                if debugMode {
                    Divider()

                    Text("Debug Mode")
                        .font(.title)
                        .bold()

                    Text("Schedule ping in -10 seconds")
                        .bold()

                    Button(action: {
                        let now = Date()
                        guard let lastPing = store.pingService.answerablePings.last else {
                            return
                        }
                        var cursor = lastPing
                        while cursor.date < now {
                            cursor = cursor.nextPing(averagePingInterval: 10)
                        }
                        store.pingService.appendPing(cursor)
                        store.alertService.present(message: "Scheduled a ping that is \(cursor.date.timeIntervalSinceNow) seconds later")
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
            .environmentObject(Settings())
            .environmentObject(Stub.store)
    }
}
