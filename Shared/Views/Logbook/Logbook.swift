//
//  Logbook.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import SwiftUI

struct Logbook: View {
    var answers: [Answer]

    @State private var showingSheet = false

    private var answersToday: [Answer] {
        answers
            .filter { Calendar.current.isDateInToday($0.ping.date) }
    }

    private var answersYesterday: [Answer] {
        answers
            .filter { Calendar.current.isDateInYesterday($0.ping.date) }
    }

    private var answersOther: [Answer] {
        answers
            .filter { !Calendar.current.isDateInToday($0.ping.date) }
            .filter { !Calendar.current.isDateInYesterday($0.ping.date) }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private var header: some View {
        VStack(alignment: .leading) {
            Text("Logbook")
                .font(.title)
                .bold()
            Text("Answered answers")
                .font(.subheadline)
        }
    }

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
                        Text(answer.tags.map({ $0.name }).joined(separator: " "))
                        Text(dateFormatter.string(from: answer.ping.date))
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
            LazyVGrid(columns: [GridItem()], alignment: .leading, spacing: 2, pinnedViews: []) {
                Section(header: header) {}

                if answersToday.count > 0 {
                    Section(header: sectionHeader(title: "Today", subtitle: "Sun, 28 March")) {
                        ForEach(answersToday) { answer in
                            Button(action: { showingSheet = true }) {
                                HStack {
                                    Spacer()
                                    VStack {
                                        Text(answer.tags.map({ $0.name }).joined(separator: " "))
                                        Text(dateFormatter.string(from: answer.ping.date))
                                    }
                                    .foregroundColor(.white)
                                    Spacer()
                                }
                            }
                            .background(Color.hsb(211, 26, 86))
                            .cornerRadius(10)
                            .sheet(isPresented: $showingSheet) {
                                VStack {
                                    Text(answer.tags.map({ $0.name }).joined(separator: " "))
                                    Text(dateFormatter.string(from: answer.ping.date))
                                }
                            }
                        }
                    }
                }

                if answersYesterday.count > 0 {
                    Section(header: sectionHeader(title: "Yesterday", subtitle: "Sat, 27 March")) {
                        ForEach(answersYesterday) { answer in
                            HStack {
                                Spacer()
                                VStack {
                                    Text(answer.tags.map({ $0.name }).joined(separator: " "))
                                    Text(dateFormatter.string(from: answer.ping.date))
                                }
                                .foregroundColor(.white)
                                Spacer()
                            }
                            .background(Color.hsb(211, 26, 86))
                            .cornerRadius(10)
                        }
                    }
                }
            }
        }
    }
}

struct Logbook_Previews: PreviewProvider {
    static var previews: some View {
        Logbook(answers: Stub.answers)
    }
}
