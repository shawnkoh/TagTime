//
//  AnswerService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 17/4/21.
//

import Foundation
import Combine

protocol AnswerService {
    static var countPerPage: Int { get }

    /// [Answer.id: Answer]
    var answers: [String: Answer] { get }
    var answersPublisher: Published<[String: Answer]>.Publisher { get }
    var latestAnswer: Answer? { get }
    var latestAnswerPublisher: Published<Answer?>.Publisher { get }

    var hasLoadedAllAnswers: Bool { get }
    var hasLoadedAllAnswersPublisher: Published<Bool>.Publisher { get }

    func getMoreCachedAnswers()

    #if DEBUG
    func deleteAllAnswers()
    #endif
}

extension AnswerService {
    static var countPerPage: Int { 64 }
}
