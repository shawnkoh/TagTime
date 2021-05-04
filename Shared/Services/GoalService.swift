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
    static let shared = GoalService()

    @Published private(set) var goals: [Goal] = []
    @Published private(set) var trackedGoals: [Goal] = []
    var untrackedGoals: [Goal] {
        goals.filter {
            let set = Set(trackedGoals)
            return !set.contains($0)
        }
    }

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
            }
            .store(in: &serviceSubscribers)
    }

    private func setup(user: User?) {
        subscribers.forEach { $0.cancel() }
        subscribers = []
        listeners.forEach { $0.remove() }
        listeners = []
        guard let user = user else {
            return
        }
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

    func trackGoal(_ goal: Goal) {}

    func untrackGoal(_ goal: Goal) {}
}

private extension User {
}
