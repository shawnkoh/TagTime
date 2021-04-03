//
//  PingCard.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/4/21.
//

import SwiftUI

// Reference: https://developer.apple.com/videos/play/wwdc2020/10040/
struct PingAnswererConfig {
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

struct PingCard: View {
    // TODO: I'm not sure if we should use EnvironmentObject here, but I'm not sure how else
    // I can delete the ping from MissedPingList.
    @EnvironmentObject var modelData: ModelData
    @State private var config = PingAnswererConfig()

    let ping: Ping

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
                Text(dateFormatter.string(from: ping.date))
                    .foregroundColor(.primary)
                    .padding()
                Spacer()
            }
            .background(Color.hsb(211, 26, 86))
            .cornerRadius(10)
        }
        .sheet(isPresented: $config.isPresented) {
            PingAnswerer(config: $config, ping: ping)
                .onDisappear {
                    guard config.needsSave else {
                        return
                    }
                    let tags = config.answer.split(separator: " ").map { Tag(name: String($0)) }
                    let answer = Answer(ping: ping, tags: tags)
                    modelData.answers.append(answer)
                }
        }
    }
}

struct PingCard_Previews: PreviewProvider {
    @State private var config = PingAnswererConfig()

    static var previews: some View {
        PingCard(ping: Stub.pings.first!)
            .environmentObject(ModelData())
    }
}
