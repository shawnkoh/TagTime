//
//  Statistics.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 2/4/21.
//

import SwiftUI
import Resolver

struct Statistics: View {
    @StateObject private var viewModel = StatisticsViewModel()

    var body: some View {
        VStack(alignment: .leading) {
            PageTitle(title: "Statistics", subtitle: "Quantified Self")

            HStack {
                DatePicker("Date", selection: $viewModel.date, in: viewModel.startDate...Date(), displayedComponents: .date)

                Picker("", selection: $viewModel.mode) {
                    ForEach(StatisticsViewModel.Mode.allCases, id: \.self) {
                        Text($0.rawValue)
                            .tag($0.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            if let dayView = viewModel.dayView {
                List {
                    Section(header: "Goals") {
                        ForEach(dayView.goals, id: \.self) { goal in
                            HStack {
                                Text("\(goal.percentage)%")
                                    .frame(width: 33, alignment: .leading)

                                Text(goal.slug)
                                    .frame(width: 180, alignment: .leading)

                                ProgressView(
                                    value: Double(goal.time.minutes),
                                    total: Double(dayView.totalMinutes)
                                )

                                Text("\(goal.time.formatted.hours) hr \(goal.time.formatted.minutes) min")
                                    .frame(width: 90, alignment: .trailing)
                            }
                            .tag(goal)
                        }
                    }

                    Section(header: "Tags") {
                        ForEach(dayView.rows, id: \.self) { row in
                            HStack {
                                Text("\(row.percentage)%")
                                    .frame(width: 33, alignment: .leading)

                                Text(row.tag)
                                    .frame(width: 180, alignment: .leading)

                                ProgressView(
                                    value: Double(row.time.minutes),
                                    total: Double(dayView.totalMinutes)
                                )

                                Text("\(row.time.formatted.hours) hr \(row.time.formatted.minutes) min")
                                    .frame(width: 90, alignment: .trailing)
                            }
                            .tag(row)
                        }
                    }
                }
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
