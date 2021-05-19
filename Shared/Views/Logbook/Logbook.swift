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
    @LazyInjected private var answerService: AnswerService

    @Published private(set) var answers: [Answer] = []
    @Published private(set) var hasLoadedAllAnswers = false

    private var subscribers = Set<AnyCancellable>()

    let sectionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private var answersSortedByDate: [[Answer]] {
        let dictionary = Dictionary(grouping: answers) { answer -> DateComponents? in
            Calendar.current.dateComponents([.day, .month, .year], from: answer.ping)
        }
        return dictionary.keys
            .compactMap { $0 }
            .sorted {
                Calendar.current.date(from: $0)! > Calendar.current.date(from: $1)!
            }
            .compactMap { date in
                dictionary[date]?.sorted { $0.ping > $1.ping }
            }
    }

    var groupedAnswers: [[Group<Answer>]] {
        answersSortedByDate
            .map { $0.grouped { $0.tags == $1.tags } }
    }

    init() {
        answerService.answersPublisher
            .map { answers in
                answers
                    .map { $0.value }
                    .sorted { $0.ping > $1.ping }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.answers = $0 }
            .store(in: &subscribers)

        answerService.hasLoadedAllAnswersPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.hasLoadedAllAnswers = $0 }
            .store(in: &subscribers)
    }

    func getMoreCachedAnswers() {
        answerService.getMoreCachedAnswers()
    }
}

struct Logbook: View {
    @StateObject private var viewModel = LogbookViewModel()
    @State private var showingSheet: Answer? = nil

    @ViewBuilder
    private func sectionHeader(title: String, subtitle: String?) -> some View {
        if let subtitle = subtitle {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.title)
                    .bold()
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        } else {
            Text(title)
                .font(.title)
                .bold()
        }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem()], alignment: .leading, spacing: 2) {
                PageTitle(title: "Logbook", subtitle: "Answered pings")

                ForEach(viewModel.groupedAnswers, id: \.self) { groups in
                    ForEach(groups, id: \.self) { group in
                        switch group {
                        case let .single(answer):
                            LogbookCard(answer: answer)
                        case let .multiple(answers):
                            AnswerGroup(answers: answers)
                        }
                    }
                }

                if !viewModel.hasLoadedAllAnswers {
                    ProgressView()
                        .onAppear(perform: viewModel.getMoreCachedAnswers)
                }
            }
        }
    }
}

struct Logbook_Previews: PreviewProvider {
    static var previews: some View {
        #if DEBUG
        Resolver.root = .mock
        #endif
        return Logbook()
    }
}
