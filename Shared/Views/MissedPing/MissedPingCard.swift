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
    @EnvironmentObject var answerService: AnswerService
    @EnvironmentObject var alertService: AlertService
    @State private var config = AnswerCreatorConfig()

    let ping: Date

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        Button(action: { config.create(pingDate: ping) }) {
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
            AnswerCreator(config: $config)
                .environmentObject(self.answerService)
                .environmentObject(self.alertService)
        }
    }
}

struct MissedPingCard_Previews: PreviewProvider {
    static var previews: some View {
        MissedPingCard(ping: Stub.pings.first!)
    }
}
