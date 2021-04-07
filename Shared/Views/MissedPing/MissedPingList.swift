//
//  MissedPingList.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import SwiftUI

struct MissedPingList: View {
    @EnvironmentObject var store: Store
    @State private var answeringAll = false

    private var missedPings: [Ping] {
        let answeredPings = Set(store.answers.map { $0.ping })
        let allPings = store.pings
        return allPings
            .filter { !answeredPings.contains($0) }
    }

    private var pingsToday: [Ping] {
        missedPings
            .filter { Calendar.current.isDateInToday($0) }
    }

    private var pingsYesterday: [Ping] {
        missedPings
            .filter { Calendar.current.isDateInYesterday($0) }
    }

    private var pingsOlder: [Ping] {
        missedPings
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

    private func section<Header: View>(header: Header, pings: [Ping]) -> some View {
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
            .sheet(isPresented: $answeringAll) {
                Text("WHAT U DOING")
            }
        }
    }
}

struct MissedPingList_Previews: PreviewProvider {
    static var previews: some View {
        MissedPingList()
            .environmentObject(Store())
            .preferredColorScheme(.dark)
    }
}
