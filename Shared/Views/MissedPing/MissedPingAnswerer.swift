//
//  MissedPingAnswerer.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/4/21.
//

import SwiftUI

// Reference: https://developer.apple.com/videos/play/wwdc2020/10040/
struct MissedPingAnswererConfig {
    var isPresented = false
    var answer = ""
    // Prevent saving when the user manually dismisses
    var needsSave = false

    mutating func present() {
        isPresented = true
        // TODO: Not sure if need to reset answer and needsSave
        answer = ""
        needsSave = false
    }

    mutating func dismiss(save: Bool = false) {
        isPresented = false
        needsSave = save
    }
}

struct MissedPingAnswerer: View {
    @Binding var config: MissedPingAnswererConfig
    let ping: Ping

    var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack {
            VStack {
                Text("What are you doing")
                Text("RIGHT NOW?")
            }
            Text(dateFormatter.string(from: ping.date))

            Spacer()

            TextField("PING1 PING2", text: $config.answer, onCommit: {
                guard config.answer.count > 0 else {
                    return
                }
                config.dismiss(save: true)
            })
            .autocapitalization(.allCharacters)
            .multilineTextAlignment(.center)
            .background(Color.hsb(207, 26, 14))
            .cornerRadius(8)
            .foregroundColor(.white)

            Spacer()
        }
    }
}

struct MissedPingAnswerer_Previews: PreviewProvider {
    @State static var config = MissedPingAnswererConfig()

    static var previews: some View {
        MissedPingAnswerer(config: $config, ping: Stub.pings.first!)
    }
}
