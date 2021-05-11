//
//  AnswerService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 17/4/21.
//

import Foundation
import Combine

protocol AnswerService {
    /// [Answer.id: Answer]
    var answers: [String: Answer] { get }
    var answersPublisher: Published<[String: Answer]>.Publisher { get }
    var latestAnswer: Answer? { get }
    var latestAnswerPublisher: Published<Answer?>.Publisher { get }

    #if DEBUG
    func deleteAllAnswers()
    #endif
}
