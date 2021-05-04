//
//  BeeminderService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/5/21.
//

import Foundation
import Combine
import FirebaseFirestoreSwift
import FirebaseFirestore

final class BeeminderService: ObservableObject {
    static let shared = BeeminderService()

    let urlSession = URLSession(configuration: .default)
    private lazy var baseURL: URLComponents = {
        var url = URLComponents()
        url.scheme = "https"
        url.host = "www.beeminder.com"
        return url
    }()

    @Published private(set) var credential: BeeminderCredential?
    @Published private(set) var goals: [Goal] = []

    private var userSubscriber: AnyCancellable!
    private var subscribers = Set<AnyCancellable>()
    private var listeners = [ListenerRegistration]()
    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    init() {
        userSubscriber = AuthenticationService.shared.$user
            .sink { self.setup(user: $0) }
    }

    func setup(user: User?) {
        subscribers.forEach { $0.cancel() }
        subscribers = []
        listeners.forEach { $0.remove() }
        listeners = []
        guard let user = user else {
            self.credential = nil
            return
        }
        user.credentialDocument.addSnapshotListener { snapshot, error in
            if let error = error {
                AlertService.shared.present(message: error.localizedDescription)
            }
            let credential = try? snapshot?.data(as: BeeminderCredential.self)
            self.credential = credential
//            self.urlSession.configuration.httpAdditionalHeaders?["access_token"] = credential?.accessToken
        }
        .store(in: &listeners)
    }

    func saveCredential(_ credential: BeeminderCredential, user: User) {
        user.credentialDocument
            .setData(from: credential)
            .errorHandled(by: AlertService.shared)
    }

    func saveCredential(_ credential: BeeminderCredential) {
        guard let user = AuthenticationService.shared.user else {
            return
        }
        saveCredential(credential, user: user)
    }

    func removeCredential(user: User) {
        user.credentialDocument
            .delete()
            .errorHandled(by: AlertService.shared)
    }

    func removeCredential() {
        guard let user = AuthenticationService.shared.user else {
            return
        }
        removeCredential(user: user)
    }

    func getGoals(with credential: BeeminderCredential) {
        var url = baseURL
        url.path = "/api/v1/users/\(credential.username)/goals.json"
        url.queryItems = [.init(name: "access_token", value: credential.accessToken)]
        var request = URLRequest(url: url.url!)
        request.setValue(credential.accessToken, forHTTPHeaderField: "access_token")
        urlSession.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: [Goal].self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case let .failure(error):
                        AlertService.shared.present(message: error.localizedDescription)
                    case .finished:
                        ()
                    }
                },
                receiveValue: { goals in
                    self.goals = goals
                }
            )
            .store(in: &subscribers)
    }
}

private extension User {
    var beeminderCollection: CollectionReference {
        self.userDocument.collection("beeminder")
    }

    var credentialDocument: DocumentReference {
        beeminderCollection.document("credential")
    }
}
