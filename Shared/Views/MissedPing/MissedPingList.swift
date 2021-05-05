//
//  MissedPingList.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import SwiftUI

struct MissedPingList: View {
    @EnvironmentObject var answerService: AnswerService
    @EnvironmentObject var tagService: TagService

    @State private var batchAnswerConfig = BatchAnswerConfig()

    private var unansweredPings: [Date] {
        answerService.unansweredPings.sorted { $0 > $1 }
    }

    private var pingsToday: [Date] {
        unansweredPings
            .filter { Calendar.current.isDateInToday($0) }
    }

    private var pingsYesterday: [Date] {
        unansweredPings
            .filter { Calendar.current.isDateInYesterday($0) }
    }

    private var pingsOlder: [Date] {
        unansweredPings
            .filter {
                !Calendar.current.isDateInYesterday($0) && !Calendar.current.isDateInToday($0)
            }
    }

    private let headerDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()

    private let pingDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private func header(date: Date) -> some View {
        VStack(alignment: .leading) {
            Text(Calendar.current.isDateInToday(date) ? "Today" : "Yesterday")
                .bold()
                .foregroundColor(.primary)
            Text(headerDateFormatter.string(from: date))
                .foregroundColor(.secondary)
        }
    }

    private func section<Header: View>(header: Header, pings: [Date]) -> some View {
        Section(header: header) {
            ForEach(pings, id: \.self) { ping in
                MissedPingCard(ping: ping)
            }
        }
    }

    // TODO: What if there are no pings at all?
    // Need some placeholder. Refer to Actions

    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: [GridItem()], alignment: .leading, spacing: 2, pinnedViews: []) {
                    PageTitle(title: "Pings", subtitle: "Missed pings")

                    if pingsToday.count > 0 {
                        section(header: header(date: pingsToday.first!), pings: pingsToday)
                    }

                    if pingsYesterday.count > 0 {
                        section(header: header(date: pingsYesterday.first!), pings: pingsYesterday)
                    }
                }
            }

            if unansweredPings.count > 1 {
                Card(text: "ANSWER ALL")
                    .onPress { batchAnswerConfig.show() }
                    .sheet(isPresented: $batchAnswerConfig.isPresented) {
                        BatchAnswerCreator(config: $batchAnswerConfig)
                            .environmentObject(self.answerService)
                            .environmentObject(self.tagService)
                    }
            }
        }
    }
}

struct MissedPingList_Previews: PreviewProvider {
    static var previews: some View {
        MissedPingList()
            .environmentObject(AnswerService.shared)
            .preferredColorScheme(.dark)
    }
}
