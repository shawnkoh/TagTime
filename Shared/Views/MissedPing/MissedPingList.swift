//
//  MissedPingList.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import SwiftUI
import Resolver
import Combine

final class MissedPingListViewModel: ObservableObject {
    @LazyInjected private var answerablePingService: AnswerablePingService

    @Published private(set) var unansweredPings: [Date] = []

    private var subscribers = Set<AnyCancellable>()

    let headerDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()

    init() {
        answerablePingService.$unansweredPings
            .map { $0.sorted { $0 > $1 }}
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.unansweredPings = $0 }
            .store(in: &subscribers)
    }
}

struct MissedPingList: View {
    @StateObject private var viewModel = MissedPingListViewModel()

    @State private var isBatchAnswerCreatorPresented = false

    private var unansweredPings: [Date] {
        viewModel.unansweredPings
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

    private func header(date: Date) -> some View {
        VStack(alignment: .leading) {
            Text(Calendar.current.isDateInToday(date) ? "Today" : "Yesterday")
                .bold()
                .foregroundColor(.primary)
            Text(viewModel.headerDateFormatter.string(from: date))
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
                    PageTitle(title: "Missed Pings", subtitle: "What ya doin?")

                    if pingsToday.count > 0 {
                        section(header: header(date: pingsToday.first!), pings: pingsToday)
                    }

                    if pingsYesterday.count > 0 {
                        section(header: header(date: pingsYesterday.first!), pings: pingsYesterday)
                    }
                }
            }

            if unansweredPings.count > 1 {
                Text("ANSWER ALL")
                    .onTap { isBatchAnswerCreatorPresented = true }
                    .cardButtonStyle(.modalCard)
                    .sheet(isPresented: $isBatchAnswerCreatorPresented) {
                        BatchAnswerCreator(isPresented: $isBatchAnswerCreatorPresented)
                    }
            }
        }
    }
}

struct MissedPingList_Previews: PreviewProvider {
    static var previews: some View {
        #if DEBUG
        Resolver.root = .mock
        #endif
        return MissedPingList()
            .preferredColorScheme(.dark)
    }
}
