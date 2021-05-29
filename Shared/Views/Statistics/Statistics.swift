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
                                HStack {
                                    Text("\(time.asPercentOf(total))%")
                                        .frame(width: 33, alignment: .leading)

                                    Text(tag)
                                        .frame(width: 180, alignment: .leading)

                                    ProgressView(
                                        value: Double(time.minutes),
                                        total: Double(total)
                                    )

                                    Text("\(time.formatted.hours) hr \(time.formatted.minutes) min")
                                        .frame(width: 90, alignment: .trailing)
                                }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
}

#if DEBUG
struct Statistics_Previews: PreviewProvider {
    static var previews: some View {
        Resolver.root = .mock
        return Statistics()
    }
}
#endif
