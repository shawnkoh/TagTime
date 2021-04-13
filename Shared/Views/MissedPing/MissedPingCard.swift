//
//  MissedPingCard.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/4/21.
//

import SwiftUI

struct MissedPingCard: View {
    // TODO: I'm not sure if we should use EnvironmentObject here, but I'm not sure how else
    // I can delete the ping from MissedPingList.
    @EnvironmentObject var store: Store
    @State private var config = MissedPingAnswererConfig()

    let ping: Date

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        Button(action: { config.present() }) {
            HStack {
                Spacer()
                Text(dateFormatter.string(from: ping))
                    .foregroundColor(.primary)
                    .padding()
                Spacer()
            }
            .background(Color.hsb(211, 26, 86))
            .cornerRadius(10)
        }
        .sheet(isPresented: $config.isPresented) {
            MissedPingAnswerer(config: $config, ping: ping)
                .onDisappear {
                    guard config.needsSave else {
                        return
                    }
                    let tags = config.answer.split(separator: " ").map { Tag($0) }
                    let answer = Answer(ping: ping, tags: tags)
                    store.addAnswer(answer)
                }
        }
    }
}

struct MissedPingCard_Previews: PreviewProvider {
    @State private var config = MissedPingAnswererConfig()

    static var previews: some View {
        MissedPingCard(ping: Stub.pings.first!)
            .environmentObject(Stub.store)
    }
}
