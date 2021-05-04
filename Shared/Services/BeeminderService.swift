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
    let credential: BeeminderCredential
    let urlSession = URLSession(configuration: .default)
    private lazy var baseURL: URLComponents = {
        var url = URLComponents()
        url.scheme = "https"
        url.host = "www.beeminder.com"
        return url
    }()

    init(credential: BeeminderCredential) {
        self.credential = credential
    }

    @Published private(set) var goals: [Goal] = []

    private var subscribers = Set<AnyCancellable>()
    private var listeners = [ListenerRegistration]()
    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    func setup() {
        subscribers.forEach { $0.cancel() }
        subscribers = []
        listeners.forEach { $0.remove() }
        listeners = []
    }

    func getGoals() {
        // TODO: Filter for updated date to prevent overfetching goals
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
}
