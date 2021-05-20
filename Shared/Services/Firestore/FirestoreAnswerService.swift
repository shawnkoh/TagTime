//
//  FirestoreAnswerService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 12/5/21.
//

import Foundation
import Combine
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import Resolver

final class FirestoreAnswerService: AnswerService {
    @LazyInjected private var authenticationService: AuthenticationService
    @LazyInjected private var goalService: GoalService
    @LazyInjected private var tagService: TagService
    @LazyInjected private var alertService: AlertService

    @Published private(set) var answers: [String: Answer] = [:]
    var answersPublisher: Published<[String : Answer]>.Publisher { $answers }
    @Published private(set) var latestAnswer: Answer?
    var latestAnswerPublisher: Published<Answer?>.Publisher { $latestAnswer }

    @Published private var lastFetched: LastFetchedStatus = .loading

    // Pagination
    @Published private(set) var hasLoadedAllAnswers = false
    var hasLoadedAllAnswersPublisher: Published<Bool>.Publisher { $hasLoadedAllAnswers }
    private var lastCachedAnswer: DocumentSnapshot?

    private var userSubscriber: AnyCancellable = .init({})

    private var subscribers = Set<AnyCancellable>()
    private var listeners = [ListenerRegistration]()
    private var serverListener: ListenerRegistration?

    private var user: User {
        authenticationService.user
    }

    private var answerCollection: CollectionReference {
        user.answerCollection
    }

    init() {
        userSubscriber = authenticationService.userPublisher
            .removeDuplicatesForServices()
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

        guard user.isAuthenticated else {
            return
        }

        getMoreCachedAnswers(user: user)
        setupFirestoreListeners(user: user)
    }

    func getMoreCachedAnswers() {
        getMoreCachedAnswers(user: user)
    }

    private func setupFirestoreListeners(user: User) {
        user.answerCollection
            .order(by: "updatedDate", descending: true)
            .limit(to: 1)
            .getDocuments(source: .cache)
            .map { try? $0.documents.first?.data(as: Answer.self)?.updatedDate }
            .replaceNil(with: user.startDate)
            .replaceError(with: user.startDate)
            // remote fetch before activating snapshot listener
            // because snapshot listener seems to not guarantee that the data is sent as a batch
            .flatMap { lastFetched -> AnyPublisher<Date, Error> in
                user.answerCollection
                    .whereField("updatedDate", isGreaterThan: lastFetched)
                    .order(by: "updatedDate")
                    .getDocuments(source: .default)
                    .flatMap { snapshot -> AnyPublisher<Date, Error> in
                        let result = snapshot.documents.compactMap { document -> (String, Answer)? in
                            guard let answer = try? document.data(as: Answer.self) else {
                                return nil
                            }
                            return (document.documentID, answer)
                        }
                        var answers = self.answers
                        result.forEach { documentId, answer in
                            answers[documentId] = answer
                        }
                        self.answers = answers

                        if let lastFetched = result.map({ $0.1.updatedDate }).max() {
                            return Just(lastFetched).setFailureType(to: Error.self).eraseToAnyPublisher()
                        } else {
                            return Just(lastFetched).setFailureType(to: Error.self).eraseToAnyPublisher()
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    self.alertService.present(message: error.localizedDescription)
                case .finished:
                    ()
                }
            }, receiveValue: { lastFetched in
                self.lastFetched = .lastFetched(lastFetched)
            })
            .store(in: &subscribers)

        $lastFetched
            // Prevents infinite recursion
            .removeDuplicates()
            .sink { lastFetched in
                self.serverListener?.remove()
                self.serverListener = nil
                guard case let .lastFetched(lastFetched) = lastFetched else {
                    return
                }

                self.serverListener = user.answerCollection
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

                        let result = snapshot.documents.compactMap { document -> (String, Answer)? in
                            guard let answer = try? document.data(as: Answer.self) else {
                                return nil
                            }
                            return (document.documentID, answer)
                        }

                        var answers = self.answers
                        result.forEach { id, answer in
                            answers[id] = answer
                        }
                        self.answers = answers

                        if let lastFetched = result.map({ $0.1.updatedDate }).max() {
                            self.lastFetched = .lastFetched(lastFetched)
                        }
                    }
            }
            .store(in: &subscribers)

        // Watch for latest answer only here because the user might edit an old answer
        user.answerCollection
            .order(by: "ping", descending: true)
            .limit(to: 1)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    self.alertService.present(message: error.localizedDescription)
                }
                self.latestAnswer = try? snapshot?.documents.first?.data(as: Answer.self)
            }
            .store(in: &listeners)
    }

    private func getMoreCachedAnswers(user: User) {
        var query = user.answerCollection
            .order(by: "ping", descending: true)
            .limit(to: Self.countPerPage)

        if let lastCachedAnswer = lastCachedAnswer {
            query = query.start(afterDocument: lastCachedAnswer)
        }

        query
            .getDocuments(source: .cache)
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    self.alertService.present(message: error.localizedDescription)
                case .finished:
                    ()
                }
            }, receiveValue: { snapshot in
                var answers = self.answers
                snapshot.documents.forEach {
                    answers[$0.documentID] = try? $0.data(as: Answer.self)
                }
                self.answers = answers

                self.lastCachedAnswer = snapshot.documents.last
                self.hasLoadedAllAnswers = Self.countPerPage > snapshot.documents.count
            })
            .store(in: &subscribers)
    }
}

extension User {
    var answerCollection: CollectionReference {
        userDocument.collection("answers")
    }
}

#if DEBUG
extension FirestoreAnswerService {
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
