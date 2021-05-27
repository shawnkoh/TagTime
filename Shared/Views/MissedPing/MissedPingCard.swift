//
//  MissedPingCard.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/4/21.
//

import SwiftUI
import Resolver

struct MissedPingCard: View {
    @State private var config = AnswerCreatorConfig()

    let ping: Date

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        Text(dateFormatter.string(from: ping))
            .onTap { config.create(pingDate: ping) }
            .cardButtonStyle(.baseCard)
            .sheet(isPresented: $config.isPresented) {
                AnswerCreator(config: $config)
            }
    }
}

#if DEBUG
struct MissedPingCard_Previews: PreviewProvider {
    static let pingService: PingService = {
        Resolver.root = .mock
        return Resolver.resolve()
    }()

    static var previews: some View {
        MissedPingCard(ping: pingService.answerablePings.first!.date)
    }
}
#endif
