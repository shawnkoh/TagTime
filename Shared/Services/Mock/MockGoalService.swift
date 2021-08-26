//
//  MockGoalService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 12/5/21.
//

import Foundation
import Combine
import Beeminder
import Resolver

final class MockGoalService: GoalService {
    @LazyInjected private var authenticationService: AuthenticationService
    @LazyInjected private var beeminderCredentialService: BeeminderCredentialService

    @Published var goals: [Goal] = []
    var goalsPublisher: Published<[Goal]>.Publisher { $goals }

    @Published var goalTrackers: [String : GoalTracker] = [:]
    var goalTrackersPublisher: Published<[String : GoalTracker]>.Publisher { $goalTrackers}

    private var subscribers = Set<AnyCancellable>()

    init() {
        authenticationService.userPublisher
            .sink { user in
                self.reset()
                guard user.isAuthenticated else {
                    return
                }
            }
            .store(in: &subscribers)

        beeminderCredentialService.credentialPublisher
            .sink { credential in
                guard credential != nil else {
                    self.reset()
                    return
                }
                self.getGoals()
                    .replaceError(with: ())
                    .sink(receiveValue: {})
                    .store(in: &self.subscribers)
            }
            .store(in: &subscribers)
    }

    private func reset() {
        goals = []
        goalTrackers = [:]
    }

    func getGoals() -> AnyPublisher<Void, Error> {
        goals = [
            .init(id: "1",
                  slug: "wasteman",
                  updatedAt: Int(Date().timeIntervalSince1970),
                  title: "Wasteman",
                  fineprint: nil,
                  autodata: nil,
                  thumbUrl: "",
                  goalType: .drinker,
                  losedate: Int(Date().addingTimeInterval(60*60*10).timeIntervalSince1970),
                  safebuf: nil,
                  pledge: 5,
                  deadline: 1,
                  gunits: "abc",
                  baremin: "abc"
            ),
            .init(
                id: "2",
                slug: "exercise",
                updatedAt: Int(Date().timeIntervalSince1970),
                title: "Exercise",
                fineprint: nil,
                autodata: nil,
                thumbUrl: "",
                goalType: .hustler,
                losedate: Int(Date().addingTimeInterval(60*60*10).timeIntervalSince1970),
                safebuf: nil,
                pledge: 5,
                deadline: Int(Date().addingTimeInterval(60*60*10).timeIntervalSince1970),
                gunits: "abc",
                baremin: ""
            )
        ]

        goalTrackers[goals.first!.id] = .init(tags: ["facebook", "youtube", "netflix"], updatedDate: Date())
        goalTrackers[goals[1].id] = .init(tags: ["yoga", "gymming", "running"], updatedDate: Date())

        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func trackGoal(_ goal: Goal) -> Future<Void, Error> {
        Future { promise in
            self.goalTrackers[goal.id] = GoalTracker(tags: [], updatedDate: Date())
            promise(.success(()))
        }
    }

    func untrackGoal(_ goal: Goal) -> Future<Void, Error> {
        Future { promise in
            self.goalTrackers[goal.id] = nil
            promise(.success(()))
        }
    }

    func trackTags(_ tags: [Tag], for goal: Goal) -> Future<Void, Error> {
        Future { promise in
            self.goalTrackers[goal.id] = GoalTracker(tags: tags, updatedDate: Date())
            promise(.success(()))
        }
    }

    // TODO: Maybe this should belong to a Datapoint service.
    func updateTrackedGoals(answer: Answer) -> AnyPublisher<Void, Error> {
        Future { promise in
            promise(.success(()))
        }
        .eraseToAnyPublisher()
    }

    func updateHyperSketch() {}
}
