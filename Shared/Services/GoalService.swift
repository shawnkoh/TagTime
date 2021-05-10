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

    @Published private(set) var goals: [Goal] = []
    @Published private(set) var goalTrackers: [String: GoalTracker] = [:]
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

    @Injected private var alertService: AlertService
    @Injected private var authenticationService: AuthenticationService
    @Injected private var beeminderCredentialService: BeeminderCredentialService

    private var user: User {
        authenticationService.user
    }
    
    init() {
        authenticationService.$user
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

        user.goalCollection.addSnapshotListener { snapshot, error in
            if let error = error {
                self.alertService.present(message: error.localizedDescription)
            }

            var goalTrackers = [String: GoalTracker]()
            snapshot?.documents.forEach { document in
                goalTrackers[document.documentID] = try? document.data(as: GoalTracker.self)
            }
            self.goalTrackers = goalTrackers
        }
        .store(in: &listeners)
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

    func createDatapointsForTrackedGoals(answer: Answer) -> AnyPublisher<Void, Error> {
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

    func deleteManualDatapoints(for goal: Goal) -> AnyPublisher<Void, Error> {
        guard let beeminderApi = beeminderApi else {
            return Fail(error: AuthError.notAuthenticated).eraseToAnyPublisher()
        }

        return beeminderApi.getDatapoints(slug: goal.slug, sort: nil, count: nil, page: nil, per: nil)
            .flatMap { datapoints -> AnyPublisher<Void, Error> in
                let deletePublishers = datapoints
                    .filter { $0.requestid == nil }
                    // TODO: We need to further filter here to protect existing datapoints before the user started TagTime.
                    // option 1: timestamp > user.startDate
                    // option 2: timestamp within last 7 days
                    // option 3: save all datapoints that exist before importing and filter them
                    // option 4: just don't delete datapoints and we won't have to deal with this issue
                    // i suspect option 4 is a better choice because we have to rewrite the code anyway when we get official integration
                    .map { beeminderApi.deleteDatapoint(slug: goal.slug, id: $0.id) }

                return Publishers.MergeMany(deletePublishers)
                    .collect()
                    .map { _ in }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func getTrackedGoalsToUpdate(answer: Answer) -> [Goal] {
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
