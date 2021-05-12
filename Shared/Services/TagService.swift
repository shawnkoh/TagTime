//
//  TagService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 28/4/21.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseFirestoreSwift

protocol TagService {
    var tags: [Tag: TagCache] { get}
    var tagsPublisher: Published<[Tag: TagCache]>.Publisher { get }
    var activeTagsPublisher: AnyPublisher<[Tag], Never> { get }

    func registerTags(_ tags: [Tag], with batch: WriteBatch?, increment: Int)
    func deregisterTags(_ tags: [Tag], with batch: WriteBatch?, decrement: Int)

    #if DEBUG
    func resetTagCache()
    #endif
}

extension TagService {
    var activeTagsPublisher: AnyPublisher<[Tag], Never> {
        tagsPublisher
            .flatMap {
                $0.publisher
                    .filter { $0.value.count > 0 }
                    .map { $0.key }
                    .collect()
            }
            .eraseToAnyPublisher()
    }
}
