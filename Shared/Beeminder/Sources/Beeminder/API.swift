//
//  BeeminderAPI.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 3/5/21.
//

import Foundation
import Combine

public final class API {
    public let credential: Credential

    private let urlSession = URLSession(configuration: .default)
    private lazy var baseURL: URLComponents = {
        var url = URLComponents()
        url.scheme = "https"
        url.host = "www.beeminder.com"
        url.path = "/api/v1/users/\(credential.username)/"
        url.queryItems = [.init(name: "access_token", value: credential.accessToken)]
        return url
    }()

    private var subscribers = Set<AnyCancellable>()
    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    private lazy var encoder: JSONEncoder = {
        let decoder = JSONEncoder()
        decoder.keyEncodingStrategy = .convertToSnakeCase
        return decoder
    }()

    public init(credential: Credential) {
        self.credential = credential
    }

    /// Get user u's list of goals.
    public func getGoals() -> AnyPublisher<[Goal], Error> {
        // TODO: Filter for updated date to prevent overfetching goals
        var url = baseURL
        url.path.append("goals.json")
        let request = URLRequest(url: url.url!)
        return urlSession.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: [Goal].self, decoder: decoder)
            .eraseToAnyPublisher()
    }

    /// Get the list of datapoints for user u's goal g — beeminder.com/u/g.
    /// - Parameters:
    ///    - sort: Which attribute to sort on. Defaults to id if none given.
    ///    - count: Limit results to count number of datapoints. Defaults to all datapoints if parameter is missing.
    ///    - page: Used to paginate results.
    ///    - per: Number of results per page. Default 25. Ignored without page parameter.
    public func getDatapoints(for slug: String, sort: String?, count: Int?, page: Int?, per: Int?) -> AnyPublisher<[Datapoint], Error> {
        var url = baseURL
        url.path.append("goals/\(slug)/datapoints.json")
        if let sort = sort {
            url.queryItems?.append(.init(name: "sort", value: sort))
        }
        if let count = count {
            url.queryItems?.append(.init(name: "count", value: "\(count)"))
        }
        if let page = page {
            url.queryItems?.append(.init(name: "page", value: "\(page)"))
        }
        if let per = per {
            url.queryItems?.append(.init(name: "per", value: "\(per)"))
        }
        let request = URLRequest(url: url.url!)
        return urlSession.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: [Datapoint].self, decoder: decoder)
            .eraseToAnyPublisher()
    }

    /// Add a new datapoint to user u's goal g — beeminder.com/u/g.
    /// - Parameters:
    ///     - value:
    ///     - timestamp: Defaults to "now" if none is passed in, or the existing timestamp if the datapoint is being updated rather than created (see requestid below).
    ///     - daystamp: Optionally you can include daystamp instead of the timestamp. If both are included, timestamp takes precedence.
    ///     - comment:
    ///     - requestid: Uniquely identifies this datapoint (scoped to this goal. The same requestid can be used for different goals without being considered a duplicate). Clients can use this to verify that Beeminder received a datapoint (important for clients with spotty connectivity). Using requestids also means clients can safely resend datapoints without accidentally creating duplicates. If requestid is included and the datapoint is identical to the existing datapoint with that requestid then the datapoint will be ignored (the API will return "duplicate datapoint"). If requestid is included and the datapoint differs from the existing one with the same requestid then the datapoint will be updated. If no datapoint with the requestid exists then the datapoint is simply created. In other words, this is an upsert endpoint and requestid is an idempotency key. NB: If you're sending multiple create datapoint requests in rapid succession (within say < 100-500ms of each other) using this endpoint, and sending the same requestid, it's not guaranteed that the datapoints won't be duplicated, as you might expect.
    public func createDatapoint(slug: String, value: Double, timestamp: Int?, daystamp: String?, comment: String?, requestid: String?) -> AnyPublisher<Datapoint, Error> {
        struct Body: Codable {
            let value: Double
            let timestamp: Int?
            let daystamp: String?
            let comment: String?
            let requestid: String?
        }

        let body = Body(value: value, timestamp: timestamp, daystamp: daystamp, comment: comment, requestid: requestid)

        var url = baseURL
        url.path.append("goals/\(slug)/datapoints.json")

        let request = makePostRequest(url: url.url!, httpBody: try! encoder.encode(body))
        return urlSession.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: Datapoint.self, decoder: decoder)
            .eraseToAnyPublisher()
    }

    private func makePostRequest(url: URL, httpBody: Data?) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        return request
    }
}
