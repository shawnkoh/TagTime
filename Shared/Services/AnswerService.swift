//
//  AnswerService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 17/4/21.
//

import Foundation
import Combine
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import Resolver

final class AnswerService: ObservableObject {
    @Injected private var authenticationService: AuthenticationService
    @Injected private var goalService: GoalService
    @Injected private var tagService: TagService
    @Injected private var alertService: AlertService

    // [Answer.id: Answer]
    @Published private(set) var answers: [String: Answer] = [:]
    @Published private(set) var latestAnswer: Answer?
    @Published private var lastFetched: LastFetchedStatus = .loading

    private var userSubscriber: AnyCancellable = .init({})

    private var subscribers = Set<AnyCancellable>()
    private var listeners = [ListenerRegistration]()

    private var user: User {
        authenticationService.user
    }

    private var answerCollection: CollectionReference {
        user.answerCollection
    }

    init() {
        userSubscriber = authenticationService.$user
            .sink { self.setup(user: $0) }
    }

    private func setup(user: User) {
        listeners.forEach { $0.remove() }
        listeners = []
        subscribers.forEach { $0.cancel() }
        subscribers = []
        answers = [:]
        latestAnswer = nil
        lastFetched = .loading

        guard user.id != AuthenticationService.unauthenticatedUserId else {
            return
        }

        setupFirestoreListeners(user: user)
    }

    private func setupFirestoreListeners(user: User) {
        user.answerCollection
            .order(by: "updatedDate", descending: true)
            .limit(to: 1)
            .getDocuments(source: .cache)
            .map { try? $0.documents.first?.data(as: Answer.self)?.updatedDate }
            .replaceNil(with: user.startDate)
            .replaceError(with: user.startDate)
            .sink { lastFetched in
                self.lastFetched = .lastFetched(lastFetched)
            }
            .store(in: &subscribers)

        user.answerCollection
            .order(by: "ping", descending: true)
            // TODO: Nasty cyclic dependency
            .limit(to: AnswerablePingService.answerablePingCount)
            .addSnapshotListener { [self] (snapshot, error) in
                if let error = error {
                    alertService.present(message: "setupFirestoreListeners \(error.localizedDescription)")
                }

                guard let snapshot = snapshot else {
                    return
                }
                let results = snapshot.documents.compactMap { answer -> (String, Answer)? in
                    guard let answer = try? answer.data(as: Answer.self) else {
                        return nil
                    }
                    return (answer.id, answer)
                }

                results.forEach { id, answer in
                    self.answers[id] = answer
                }
                latestAnswer = results.first?.1
            }
            .store(in: &listeners)
    }
}

extension User {
    var answerCollection: CollectionReference {
        userDocument.collection("answers")
    }
}

#if DEBUG
extension AnswerService {
    func deleteAllAnswers() {
        // TODO: This has a limit of 500 writes, we should ideally split tags into multiple chunks of 500
        answerCollection.getDocuments(source: .cache) { result, error in
            if let error = error {
                self.alertService.present(message: error.localizedDescription)
            }
            guard let result = result else {
                return
            }
            let writeBatch = Firestore.firestore().batch()
            result.documents.forEach { writeBatch.deleteDocument($0.reference) }
            writeBatch.commit() { error in
                if let error = error {
                    self.alertService.present(message: error.localizedDescription)
                }
            }
        }

        answerCollection.getDocuments() { result, error in
            if let error = error {
                self.alertService.present(message: error.localizedDescription)
            }
            guard let result = result else {
                return
            }
            let writeBatch = Firestore.firestore().batch()
            result.documents.forEach { writeBatch.deleteDocument($0.reference) }
            writeBatch.commit() { error in
                if let error = error {
                    self.alertService.present(message: error.localizedDescription)
                }
            }
        }
    }
}
#endif
