//
//  MissedPingList.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import SwiftUI

struct MissedPingList: View {
    var pings: [Ping]

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

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Pings")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                    Text("Missed pings")
                        .font(.title2)
                        .foregroundColor(.hsb(0, 0, 39))
                }

                if pingsToday.count > 0 {
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading) {
                            Text("Today")
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.white)
                            Text(headerDateFormatter.string(from: pingsToday.first!.date))
                                .font(.title2)
                                .foregroundColor(Color.hsb(0, 0, 39))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(pingsToday) { ping in
                                HStack {
                                    Spacer()
                                    Button(pingDateFormatter.string(from: ping.date)) {
                                        print("\(ping.date) tapped")
                                    }
                                    .background(Color.hsb(211, 26, 86))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    Spacer()
                                }
                            }
                        }
                    }
                }

                if pingsYesterday.count > 0 {
                    VStack(alignment: .leading) {
                        Text("Yesterday")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.white)
                        Text(headerDateFormatter.string(from: pingsYesterday.first!.date))
                            .font(.title2)
                            .foregroundColor(Color.hsb(0, 0, 39))
                    }

                    ForEach(pingsYesterday) { ping in
                        Button(pingDateFormatter.string(from: ping.date)) {
                            print("\(ping.date) tapped")
                        }
                        .background(Color.hsb(211, 26, 86))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }

                Button("ANSWER ALL") {
                    print("ANSWER ALL")
                    print(pingsYesterday.count)
                }
                .foregroundColor(.white)
                .background(Color.hsb(223, 69, 90))
            }
            Spacer()
        }
        .background(Color.black)
    }
}

struct MissedPingList_Previews: PreviewProvider {
    static var previews: some View {
        MissedPingList(pings: Stub.pings)
            .preferredColorScheme(.dark)
    }
}
