//
//  MissedPingList.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import SwiftUI

struct MissedPingList: View {
    var pings: [Ping]
    @State private var answeringOne: Ping? = nil
    @State private var answeringAll = false

    private var pingsToday: [Ping] {
        pings
            .filter { Calendar.current.isDateInToday($0.date) }
    }

    private var pingsYesterday: [Ping] {
        pings
            .filter { Calendar.current.isDateInYesterday($0.date) }
    }

    private var pingsOlder: [Ping] {
        pings
            .filter {
                !Calendar.current.isDateInYesterday($0.date) && !Calendar.current.isDateInToday($0.date)
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
            ForEach(pings) { ping in
                Button(action: { answeringOne = ping }) {
                    HStack {
                        Spacer()
                        Text(pingDateFormatter.string(from: ping.date))
                            .foregroundColor(.primary)
                            .padding()
                        Spacer()
                    }
                    .background(Color.hsb(211, 26, 86))
                    .cornerRadius(10)
                }
                .sheet(item: $answeringOne) { ping in
                    Text(pingDateFormatter.string(from: ping.date))
                }
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
                        section(header: header(date: pingsToday.first!.date), pings: pingsToday)
                    }

                    if pingsYesterday.count > 0 {
                        section(header: header(date: pingsYesterday.first!.date), pings: pingsYesterday)
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
        MissedPingList(pings: Stub.pings)
            .preferredColorScheme(.dark)
    }
}
