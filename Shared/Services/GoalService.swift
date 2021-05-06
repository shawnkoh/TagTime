//
//  File.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 4/5/21.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine
import Beeminder

final class GoalService: ObservableObject {
    enum Errors: Error {
        case notAuthenticated
    }

    static let shared = GoalService()

    @Published private(set) var goals: [Goal] = []
    @Published private(set) var goalTrackers: [String: GoalTracker] = [:]
    var trackedGoals: [Goal] {
        goals.filter { goalTrackers[$0.id] != nil }
    }
    var untrackedGoals: [Goal] {
        goals.filter { goalTrackers[$0.id] == nil }
    }

    private var goalApi: GoalAPI?
    private var beeminderApi: Beeminder.API?
    private var serviceSubscribers = Set<AnyCancellable>()
    private var subscribers = Set<AnyCancellable>()
    private var listeners = [ListenerRegistration]()

    init() {
        AuthenticationService.shared.$user
            .sink { self.setup(user: $0) }
            .store(in: &serviceSubscribers)

        BeeminderCredentialService.shared.$credential
            .sink {
                guard let credential = $0 else {
                    self.beeminderApi = nil
                    return
                }
                self.beeminderApi = .init(credential: credential)
                self.getGoals()
            }
            .store(in: &serviceSubscribers)
    }

    private func setup(user: User?) {
        subscribers.forEach { $0.cancel() }
        subscribers = []
        listeners.forEach { $0.remove() }
        listeners = []
        guard let user = user else {
            self.goalApi = nil
            return
        }
        self.goalApi = .init(user: user)

        user.goalCollection.addSnapshotListener { snapshot, error in
            if let error = error {
                AlertService.shared.present(message: error.localizedDescription)
            }

            guard let snapshot = snapshot else {
                return
            }
            var goalTrackers = [String: GoalTracker]()
            snapshot.documents.forEach { document in
                goalTrackers[document.documentID] = try? document.data(as: GoalTracker.self)
            }
            self.goalTrackers = goalTrackers
        }
        .store(in: &listeners)
    }

    func getGoals() {
        beeminderApi?.getGoals()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    AlertService.shared.present(message: error.localizedDescription)
                case .finished:
                    ()
                }
            }, receiveValue: { goals in
                self.goals = goals
            })
            .store(in: &subscribers)
    }

    func trackGoal(_ goal: Goal) -> AnyPublisher<Void, Error> {
        guard let goalApi = goalApi else {
            return Fail(error: Errors.notAuthenticated).eraseToAnyPublisher()
        }
        return goalApi.trackGoal(goal).eraseToAnyPublisher()
    }

    func untrackGoal(_ goal: Goal) -> AnyPublisher<Void, Error> {
        guard let goalApi = goalApi else {
            return Fail(error: Errors.notAuthenticated).eraseToAnyPublisher()
        }
        return goalApi.untrackGoal(goal).eraseToAnyPublisher()
    }

    func trackTags(_ tags: [Tag], for goal: Goal) -> AnyPublisher<Void, Error> {
        guard let goalApi = goalApi else {
            return Fail(error: Errors.notAuthenticated).eraseToAnyPublisher()
        }
        return goalApi.trackTags(tags, for: goal).eraseToAnyPublisher()
    }

    func updateTrackedGoals(answer: Answer) -> AnyPublisher<Void, Error> {
        guard let beeminderApi = beeminderApi else {
            return Fail(error: AuthError.notAuthenticated).eraseToAnyPublisher()
        }

        let publishers = getTrackedGoalsToUpdate(answer: answer).map { goal -> AnyPublisher<Void, Error> in
            // TODO: This should be based on dynamic ping
            let value = 45.0 / 60.0
            // TODO: update comment
            let comment = "pings: \(answer.tagDescription)"
            // Because BeeminderAPI enforces unique requestid, it prevents the user from creating additional datapoints for the same goal.
            // Because getTrackedGoalsToUpdate returns unique goals, we won't ever send multiple requests to create the same datapoint.
            return beeminderApi
                .createDatapoint(slug: goal.slug, value: value, timestamp: nil, daystamp: nil, comment: comment, requestid: answer.id)
                .map { _ in }
                .eraseToAnyPublisher()
        }
        return Publishers.MergeMany(publishers)
            .collect()
            .map { _ in }
            .eraseToAnyPublisher()
    }

    private func getTrackedGoalsToUpdate(answer: Answer) -> [Goal] {
        // any goal that contains answer.tags is a goal that needs to be tracked
        // but the goal must also be tracked
        goals.filter { goal in
            guard let tracker = goalTrackers[goal.id] else {
                return false
            }
            let commonTags = Set(tracker.tags).intersection(answer.tags)
            return commonTags.count > 0
        }
    }
}

private extension User {
    var goalCollection: CollectionReference {
        userDocument.collection("beeminder-goals")
    }
}

private final class GoalAPI {
    let user: User

    init(user: User) {
        self.user = user
    }

    func trackGoal(_ goal: Goal) -> Future<Void, Error> {
        user.goalCollection
            .document(goal.id)
            .setData(from: GoalTracker(tags: [], updatedDate: Date()))
    }

    func untrackGoal(_ goal: Goal) -> Future<Void, Error> {
        user.goalCollection
            .document(goal.id)
            .delete()
    }

    func trackTags(_ tags: [Tag], for goal: Goal) -> Future<Void, Error> {
        user.goalCollection
            .document(goal.id)
            .setData(from: GoalTracker(tags: tags, updatedDate: Date()))
    }
}
