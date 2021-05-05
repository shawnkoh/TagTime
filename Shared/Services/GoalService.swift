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
    private var beeminderApi: BeeminderAPI?
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

        guard let tracker = goalTrackers[goal.id] else {
            return goalApi.trackTags(tags, for: goal).eraseToAnyPublisher()
        }

        let oldTags = Set(tracker.tags)
        let appendTags = tags.filter { !oldTags.contains($0) }
        var newTags = tracker.tags
        newTags.append(contentsOf: appendTags)
        return goalApi.trackTags(newTags, for: goal).eraseToAnyPublisher()
    }

    func untrackTags(_ tags: [Tag], for goal: Goal) -> AnyPublisher<Void, Error> {
        guard let goalApi = goalApi else {
            return Fail(error: Errors.notAuthenticated).eraseToAnyPublisher()
        }

        guard let tracker = goalTrackers[goal.id] else {
            return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        let tagsToRemove = Set(tags)
        let keepTags = tracker.tags.filter { !tagsToRemove.contains($0) }
        return goalApi.trackTags(keepTags, for: goal).eraseToAnyPublisher()
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
