//
//  MissedPingList.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import SwiftUI

struct AnswerAllConfig {
    private(set) var isPresented = false
    var response = ""
    private(set) var needToSave = false

    var tags: [Tag] {
        response.split(separator: " ").map { Tag($0) }
    }

    mutating func show() {
        response = ""
        isPresented = true
    }

    mutating func dismiss(save: Bool) {
        needToSave = save
        isPresented = false
    }
}

struct MissedPingList: View {
    @EnvironmentObject var store: Store
    @State private var answeringAll = false
    @State private var answerAllConfig = AnswerAllConfig()

    private var pingsToday: [Date] {
        store.unansweredPings
            .filter { Calendar.current.isDateInToday($0) }
    }

    private var pingsYesterday: [Date] {
        store.unansweredPings
            .filter { Calendar.current.isDateInYesterday($0) }
    }

    private var pingsOlder: [Date] {
        store.unansweredPings
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

            if store.unansweredPings.count > 1 {
                Button(action: { answeringAll = true }) {
                    HStack {
                        Spacer()
                        Text("ANSWER ALL")
                            .foregroundColor(.primary)
                            .padding()
                        Spacer()
                    }
                    .background(Color.hsb(223, 69, 90))
                    .cornerRadius(8)
                }
                .sheet(
                    isPresented: $answeringAll,
                    onDismiss: {
                        guard answerAllConfig.needToSave else {
                            return
                        }
                        store.unansweredPings
                            .map { Answer(ping: $0, tags: answerAllConfig.tags) }
                            .forEach { _ = store.addAnswer($0) }
                    }
                ) {
                    VStack {
                        Text("What were you doing from")
                        Text("")
                        TextField(
                            "PING1 PING2",
                            text: $answerAllConfig.response,
                            onCommit: {
                                answerAllConfig.dismiss(save: answerAllConfig.response.count > 0)
                            }
                        )
                    }
                }
            }
        }
    }
}

struct MissedPingList_Previews: PreviewProvider {
    static var previews: some View {
        MissedPingList()
            .environmentObject(Stub.store)
            .preferredColorScheme(.dark)
    }
}
