//
//  Statistics.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import SwiftUI
import Resolver

fileprivate extension Date {
    var day: StatisticsViewModel.Day {
        let components = Calendar.current.dateComponents([.day, .month, .year], from: self)
        return .init(day: components.day!, month: components.month!, year: components.year!)
    }
}

struct Statistics: View {
    @StateObject private var viewModel = StatisticsViewModel()

    var body: some View {
        VStack(alignment: .leading) {
            PageTitle(title: "Statistics", subtitle: "Quantified Self")

            Picker("", selection: $viewModel.mode) {
                ForEach(StatisticsViewModel.Mode.allCases, id: \.self) {
                    Text($0.rawValue)
                        .tag($0.rawValue)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            DatePicker("Date", selection: $viewModel.date, in: viewModel.startDate...Date(), displayedComponents: .date)

            if
                let tags = viewModel.tagCountByDate[viewModel.date.day],
                let total = viewModel.totalByDay[viewModel.date.day]
            {
                List {
                    Section {
                        ForEach(Array(tags.keys), id: \.self) { tag in
                            if let time = tags[tag] {
                                ProgressView(
                                    value: Double(time),
                                    total: Double(total),
                                    label: { Text(tag) },
                                    currentValueLabel: { Text("\(time)") }
                                )
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
}

struct Statistics_Previews: PreviewProvider {
    static var previews: some View {
        #if DEBUG
        Resolver.root = .mock
        #endif
        return Statistics()
    }
}
