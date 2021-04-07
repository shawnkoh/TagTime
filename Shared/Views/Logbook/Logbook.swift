//
//  Logbook.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import SwiftUI

struct Logbook: View {
    @EnvironmentObject var store: Store

    @State private var showingSheet: Answer? = nil

    private var answersToday: [Answer] {
        store.answers
            .filter { Calendar.current.isDateInToday($0.ping) }
    }

    private var answersYesterday: [Answer] {
        store.answers
            .filter { Calendar.current.isDateInYesterday($0.ping) }
    }

    private var answersOther: [Answer] {
        store.answers
            .filter { !Calendar.current.isDateInToday($0.ping) }
            .filter { !Calendar.current.isDateInYesterday($0.ping) }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title)
                .bold()
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func section(answers: [Answer], title: String?) -> some View {
        Section(header: sectionHeader(title: "Today", subtitle: "Sun, 28 March")) {
            ForEach(answersToday) { answer in
                HStack {
                    Spacer()
                    VStack {
                        Text(answer.tags.joined(separator: " "))
                        Text(dateFormatter.string(from: answer.ping))
                    }
                    .foregroundColor(.white)
                    Spacer()
                }
                .background(Color.hsb(211, 26, 86))
                .cornerRadius(10)
            }
        }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem()], alignment: .leading, spacing: 2) {
                PageTitle(title: "Logbook", subtitle: "Answered pings")

                // TODO: This doesn't make sense.
                // It should for loop through an ordered series of dates, and then decide
                // what to do from there.
                // Which means we need to have a function that returns an ordered series of answers.
                // This can be done two ways, either by sorting in memory, or by relying on the database.
                // Implement the database, then find out which way to do it.
                // But first, watch the SwiftUI video!

                if answersToday.count > 0 {
                    Section(header: sectionHeader(title: "Today", subtitle: "Sun, 28 March")) {
                        ForEach(answersToday) { answer in
                            LogbookCard(answer: answer)
                        }
                    }
                }

                if answersYesterday.count > 0 {
                    Section(header: sectionHeader(title: "Yesterday", subtitle: "Sat, 27 March")) {
                        ForEach(answersYesterday) { answer in
                            LogbookCard(answer: answer)
                        }
                    }
                }
            }
        }
    }
}

struct Logbook_Previews: PreviewProvider {
    static var previews: some View {
        Logbook()
            .environmentObject(Store(user: Stub.user))
    }
}
