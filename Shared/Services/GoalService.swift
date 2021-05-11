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
import Resolver

final class GoalService: ObservableObject {
    enum Errors: Error {
        case notAuthenticated
    }

    @Injected private var alertService: AlertService
    @Injected private var authenticationService: AuthenticationService
    @Injected private var beeminderCredentialService: BeeminderCredentialService

    @Published private(set) var goals: [Goal] = []
    @Published private(set) var goalTrackers: [String: GoalTracker] = [:]
    @Published private var lastFetched: LastFetchedStatus = .loading

    var trackedGoals: [Goal] {
        goals.filter { goalTrackers[$0.id] != nil }
    }
    var untrackedGoals: [Goal] {
        goals.filter { goalTrackers[$0.id] == nil }
    }

    private var beeminderApi: Beeminder.API?
    private var serviceSubscribers = Set<AnyCancellable>()
    private var subscribers = Set<AnyCancellable>()
    private var listeners = [ListenerRegistration]()
    private var serverListener: ListenerRegistration?

    private var user: User {
        authenticationService.user
    }
    
    init() {
        authenticationService.userPublisher
            .sink { self.setup(user: $0) }
            .store(in: &serviceSubscribers)

        beeminderCredentialService.$credential
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

    private func setup(user: User) {
        subscribers.forEach { $0.cancel() }
        subscribers = []
        listeners.forEach { $0.remove() }
        listeners = []
        goalTrackers = [:]
        lastFetched = .loading
        serverListener?.remove()
        serverListener = nil

        guard user.isAuthenticated else {
            return
        }

        user.goalTrackerCollection
            .order(by: "updatedDate", descending: true)
            .limit(to: 1)
            .getDocuments(source: .cache)
            .map { try? $0.documents.first?.data(as: GoalTracker.self)?.updatedDate }
            .replaceError(with: user.startDate)
            .replaceNil(with: user.startDate)
            .sink { self.lastFetched = .lastFetched($0) }
            .store(in: &subscribers)

        user.goalTrackerCollection
            .getDocuments(source: .cache)
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    self.alertService.present(message: error.localizedDescription)
                case .finished:
                    ()
                }
            }, receiveValue: { snapshot in
                snapshot.documents.forEach { document in
                    self.goalTrackers[document.documentID] = try? document.data(as: GoalTracker.self)
                }
            })
            .store(in: &subscribers)

        $lastFetched
            // Prevent infinite recursion
            .removeDuplicates()
            .sink { lastFetched in
                self.serverListener?.remove()
                self.serverListener = nil
                guard case let .lastFetched(lastFetched) = lastFetched else {
                    return
                }

                self.serverListener = user.goalTrackerCollection
                    .whereField("updatedDate", isGreaterThan: lastFetched)
                    .addSnapshotListener { snapshot, error in
                        if let error = error {
                            self.alertService.present(message: error.localizedDescription)
                        }

                        guard let snapshot = snapshot else {
                            return
                        }

                        let result = snapshot.documents.compactMap { document -> (String, GoalTracker)? in
                            guard let tagCache = try? document.data(as: GoalTracker.self) else {
                                return nil
                            }
                            return (document.documentID, tagCache)
                        }

                        result.forEach { goalId, goalTracker in
                            self.goalTrackers[goalId] = goalTracker
                        }

                        if let lastFetched = result.map({ $0.1.updatedDate }).max() {
                            self.lastFetched = .lastFetched(lastFetched)
                        }
                    }
            }
            .store(in: &subscribers)
    }

    func getGoals() {
        beeminderApi?.getGoals()
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    self.alertService.present(message: error.localizedDescription)
                case .finished:
                    ()
                }
            }, receiveValue: { goals in
                self.goals = goals
            })
            .store(in: &subscribers)
    }

    func trackGoal(_ goal: Goal) -> Future<Void, Error> {
        user.goalTrackerCollection
            .document(goal.id)
            .setData(from: GoalTracker(tags: [], updatedDate: Date()))
    }

    func untrackGoal(_ goal: Goal) -> Future<Void, Error> {
        user.goalTrackerCollection
            .document(goal.id)
            .delete()
    }

    func trackTags(_ tags: [Tag], for goal: Goal) -> Future<Void, Error> {
        user.goalTrackerCollection
            .document(goal.id)
            .setData(from: GoalTracker(tags: tags, updatedDate: Date()))
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
    var goalTrackerCollection: CollectionReference {
        userDocument.collection("beeminder-goals")
    }
}
