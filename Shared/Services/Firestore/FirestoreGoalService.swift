//
//  FirestoreGoalService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 12/5/21.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import Resolver
import Combine
import Beeminder

final class FirestoreGoalService: GoalService {
    @LazyInjected private var alertService: AlertService
    @LazyInjected private var authenticationService: AuthenticationService
    @LazyInjected private var beeminderCredentialService: BeeminderCredentialService

    @Published private(set) var goals: [Goal] = []
    var goalsPublisher: Published<[Goal]>.Publisher { $goals }
    /// List of active GoalTrackers
    @Published private(set) var goalTrackers: [String: GoalTracker] = [:]
    var goalTrackersPublisher: Published<[String : GoalTracker]>.Publisher { $goalTrackers }

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
            .removeDuplicatesForServices()
            .sink { self.setup(user: $0) }
            .store(in: &serviceSubscribers)

        beeminderCredentialService.credentialPublisher
            .sink {
                guard let credential = $0 else {
                    self.beeminderApi = nil
                    return
                }
                self.beeminderApi = .init(credential: credential)
                self.getGoals()
                    .sink(receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            self.alertService.present(message: error.localizedDescription)
                        }
                    }, receiveValue: {})
                    .store(in: &self.subscribers)
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
            // remote fetch before activating snapshot listener
            // because snapshot listener seems to not guarantee that the data is sent as a batch
            .flatMap { lastFetched -> AnyPublisher<Date, Error> in
                user.goalTrackerCollection
                    .whereField("updatedDate", isGreaterThan: lastFetched)
                    .order(by: "updatedDate")
                    .getDocuments(source: .default)
                    .flatMap { snapshot -> AnyPublisher<Date, Error> in
                        let result = snapshot.documents.compactMap { document -> (String, GoalTracker)? in
                            guard
                                let goalTracker = try? document.data(as: GoalTracker.self),
                                goalTracker.deletedDate == nil
                            else {
                                return nil
                            }
                            return (document.documentID, goalTracker)
                        }
                        var goalTrackers = self.goalTrackers
                        result.forEach { documentId, goalTracker in
                            goalTrackers[documentId] = goalTracker
                        }
                        self.goalTrackers = goalTrackers

                        if let lastFetched = result.map({ $0.1.updatedDate }).max() {
                            return Just(lastFetched).setFailureType(to: Error.self).eraseToAnyPublisher()
                        } else {
                            return Just(lastFetched).setFailureType(to: Error.self).eraseToAnyPublisher()
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .replaceError(with: user.startDate)
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
                var goalTrackers = self.goalTrackers
                snapshot.documents.forEach { document in
                    guard
                        let goalTracker = try? document.data(as: GoalTracker.self),
                        goalTracker.deletedDate == nil
                    else {
                        return
                    }
                    goalTrackers[document.documentID] = goalTracker
                }
                self.goalTrackers = goalTrackers
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
                    // Firestore is like a hash table. If the query is not sorted, there's no guarantee it will
                    // retrieve the further updated date first.
                    .order(by: "updatedDate")
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

                        var goalTrackers = self.goalTrackers
                        result.forEach { goalId, goalTracker in
                            if goalTracker.deletedDate == nil {
                                goalTrackers[goalId] = goalTracker
                            } else {
                                goalTrackers[goalId] = nil
                            }
                        }
                        self.goalTrackers = goalTrackers

                        if let lastFetched = result.map({ $0.1.updatedDate }).max() {
                            self.lastFetched = .lastFetched(lastFetched)
                        }
                    }
            }
            .store(in: &subscribers)
    }

    func getGoals() -> AnyPublisher<Void, Error> {
        guard let beeminderApi = beeminderApi else {
            return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        return beeminderApi.getGoals()
            .map { [weak self] goals -> Void in
                self?.goals = goals
            }
            .eraseToAnyPublisher()
    }

    func trackGoal(_ goal: Goal) -> Future<Void, Error> {
        user.goalTrackerCollection
            .document(goal.id)
            .setData(from: GoalTracker(tags: [], updatedDate: Date()))
    }

    func untrackGoal(_ goal: Goal) -> Future<Void, Error> {
        guard let tracker = goalTrackers[goal.id] else {
            return Future { promise in
                promise(.success(()))
            }
        }
        let date = Date()
        let newTracker = GoalTracker(tags: tracker.tags, updatedDate: date, deletedDate: date)
        return user.goalTrackerCollection
            .document(goal.id)
            .setData(from: newTracker)
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

    func updateHyperSketch() {
        guard let beeminderApi = beeminderApi else {
            return
        }

        user.answerCollection
            .whereField("tags", arrayContains: "stickstack")
            .getDocuments(source: .server)
            .sink { completion in
                print(completion)
            } receiveValue: { [weak self] snapshot in
                guard let self = self else {
                    return
                }
                let goal = self.goals.first { goal in
                    guard let tracker = self.goalTrackers[goal.id] else {
                        return false
                    }
                    let commonTags = Set(tracker.tags).intersection(["stickstack"])
                    return commonTags.count > 0
                }
                guard let goal = goal else {
                    return
                }
                var count: Double = 0
                let publishers = snapshot.documents
                    .compactMap { try? $0.data(as: Answer.self) }
                    .map { answer -> AnyPublisher<Void, Error> in
                        // TODO: This should be based on dynamic ping
                        let value = 45.0 / 60.0
                        let comment = "pings: \(answer.tagDescription)"
                        print("updating", answer)
                        count += 1
    //                    return beeminderApi
    //                        .createDatapoint(slug: goal.slug, value: value, timestamp: nil, daystamp: nil, comment: comment, requestid: answer.id)
    //                        .map { _ in }
    //                        .eraseToAnyPublisher()
                        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
                    }

                print("count", count)

//                Publishers.MergeMany(publishers)
//                    .collect()
//                    .map { _ in }
//                    .eraseToAnyPublisher()
//                    .errorHandled(by: self.alertService)
            }
            .store(in: &subscribers)
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
