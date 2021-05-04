//
//  BeeminderAPI.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/5/21.
//

import Foundation
import Combine

final class BeeminderAPI {
    let credential: BeeminderCredential
    let urlSession = URLSession(configuration: .default)
    private lazy var baseURL: URLComponents = {
        var url = URLComponents()
        url.scheme = "https"
        url.host = "www.beeminder.com"
        return url
    }()

    private var subscribers = Set<AnyCancellable>()
    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    init(credential: BeeminderCredential) {
        self.credential = credential
    }

    func getGoals() -> AnyPublisher<[Goal], Error> {
        // TODO: Filter for updated date to prevent overfetching goals
        var url = baseURL
        url.path = "/api/v1/users/\(credential.username)/goals.json"
        url.queryItems = [.init(name: "access_token", value: credential.accessToken)]
        var request = URLRequest(url: url.url!)
        request.setValue(credential.accessToken, forHTTPHeaderField: "access_token")
        return urlSession.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: [Goal].self, decoder: decoder)
            .eraseToAnyPublisher()
    }
}
