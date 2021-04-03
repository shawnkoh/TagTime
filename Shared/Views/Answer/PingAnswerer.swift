//
//  PingAnswerer.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/4/21.
//

import SwiftUI

struct PingAnswerer: View {
    @Binding var config: PingAnswererConfig
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

struct PingAnswerer_Previews: PreviewProvider {
    @State static var config = PingAnswererConfig()

    static var previews: some View {
        PingAnswerer(config: $config, ping: Stub.pings.first!)
    }
}
