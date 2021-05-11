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
