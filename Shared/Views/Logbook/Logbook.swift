//
//  Logbook.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import SwiftUI
import Resolver
import Combine

final class LogbookViewModel: ObservableObject {
    @Injected private var answerService: AnswerService

    @Published private(set) var answers: [Answer] = []

    private var subscribers = Set<AnyCancellable>()

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    init() {
        answerService.$answers
            .map { answers in
                answers
                    .map { $0.value }
                    .sorted { $0.ping > $1.ping }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.answers = $0 }
            .store(in: &subscribers)
    }
}

struct Logbook: View {
    @StateObject private var viewModel = LogbookViewModel()
    @State private var showingSheet: Answer? = nil

    private var answers: [Answer] {
        viewModel.answers
    }

    private var answersToday: [Answer] {
        answers
            .filter { Calendar.current.isDateInToday($0.ping) }
    }

    private var answersYesterday: [Answer] {
        answers
            .filter { Calendar.current.isDateInYesterday($0.ping) }
    }

    private var answersOther: [Answer] {
        answers
            .filter { !Calendar.current.isDateInToday($0.ping) }
            .filter { !Calendar.current.isDateInYesterday($0.ping) }
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

                    .foregroundColor(.white)
                    .padding()
                    Spacer()
                }
                .background(Color.baseCard)
                .cornerRadius(8)
                VStack {
                    Text(answer.tagDescription)
                    Text(viewModel.dateFormatter.string(from: answer.ping))
                }
                .onTap { }
                .cardButtonStyle(.baseCard)
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
    }
}
