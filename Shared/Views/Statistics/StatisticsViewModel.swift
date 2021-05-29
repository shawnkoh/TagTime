//
//  StatisticsViewModel.swift
//  TagTime
//
//  Created by Shawn Koh on 27/5/21.
//

import Foundation
import Resolver
import Combine

fileprivate extension Date {
    var day: StatisticsViewModel.Day {
        let components = Calendar.current.dateComponents([.day, .month, .year], from: self)
        return .init(day: components.day!, month: components.month!, year: components.year!)
    }
}

fileprivate extension Answer {
    var day: StatisticsViewModel.Day {
        ping.day
    }
}

final class StatisticsViewModel: ObservableObject {
    enum Mode: String, CaseIterable, Hashable {
        case daily = "Day"
        case weekly = "Week"
    }

    struct Day: Hashable {
        let day: Int
        let month: Int
        let year: Int
    }

    struct Time: Hashable {
        let minutes: Int

        var formatted: (hours: Int, minutes: Int) {
            (minutes / 60, (minutes % 60))
        }

        init(minutes: Int) {
            self.minutes = minutes
        }

        func asPercentOf(_ total: Int) -> Int {
            Int((Double(minutes) / Double(total) * 100).rounded())
        }
    }

    struct DayView {
        let totalMinutes: Int
        let rows: [Row]
    }

    struct Row: Hashable {
        let tag: Tag
        let time: Time
        let percentage: Int
    }

    @LazyInjected private var answerService: AnswerService
    @LazyInjected private var authenticationService: AuthenticationService

    @Published var mode: Mode = .daily
    @Published var date = Date()
    @Published var answers: [Answer] = []

    var dayView: DayView? {
        guard
            let tags = tagCountByDate[date.day],
            let totalMinutes = totalByDay[date.day]
        else {
            return nil
        }

        let rows = tags
            .sorted { $0.key < $1.key }
            .sorted { $0.value.minutes > $1.value.minutes }
            .map { tag, time in
                Row(tag: tag, time: time, percentage: time.asPercentOf(totalMinutes))
            }

        return DayView(totalMinutes: totalMinutes, rows: rows)
    }

    var startDate: Date {
        authenticationService.user.startDate
    }

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

    var totalByDay: [Day: Int] {
        var result = [Day: Int]()
        answersSortedByDate.forEach { answers in
            guard answers.count > 0 else {
                return
            }
            result[answers.first!.day] = answers.count * 45
        }
        return result
    }

    var tagCountByDate: [Day: [Tag: Time]] {
        var result: [Day: [Tag: Time]] = [:]
        answersSortedByDate.forEach { answers in
            guard answers.count > 0 else {
                return
            }
            let date = Calendar.current.dateComponents([.day, .month, .year], from: answers.first!.ping)
            let day = Day(day: date.day!, month: date.month!, year: date.year!)
            var dictionary: [Tag: Int] = [:]
            answers.forEach { answer in
                answer.tags.forEach { tag in
                    if let row = dictionary[tag] {
                        // TODO: Should be based on sourcePingInterval
                        dictionary[tag] = row + 1 * 45
                    } else {
                        dictionary[tag] = 1 * 45
                    }
                }
            }

            var subresult: [Tag: Time] = [:]
            dictionary.forEach { tag, minutes in
                subresult[tag] = Time(minutes: minutes)
            }

            result[day] = subresult
        }
        return result
    }

    private var subscribers = Set<AnyCancellable>()

    init() {
        answerService.answersPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.answers = $0.map { $0.value } }
            .store(in: &subscribers)
    }
}
