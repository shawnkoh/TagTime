//
//  MockTagService.swift
//  TagTime (iOS)
//
//  Created by Shawn Koh on 12/5/21.
//

import Foundation
import Resolver
import Combine
import FirebaseFirestore

final class MockTagService: TagService {
    @Published var tags: [Tag : TagCache] = [:]
    var tagsPublisher: Published<[Tag : TagCache]>.Publisher { $tags }

    private var subscribers = Set<AnyCancellable>()

    // TODO: Ideally this shouldn't rely on WriteBatch
    // Indicates that there's a design problem here as none of the MockService should rely on Firestore
    // My hunch is that the answer is via AnswerBuilder
    // AnswerBuilder should be separated into AnswerBuilderExecutor and AnswerBuilder
    // then the Executor can rely on AnswerBuilder's Operations to handle it or something
    func registerTags(_ tags: [Tag], with batch: WriteBatch?, delta: Int) {
        tags.forEach { tag in
            let count: Int
            if let tagCache = self.tags[tag] {
                count = min(0, tagCache.count + delta)
            } else {
                count = min(0, delta)
            }
            self.tags[tag] = TagCache(count: count, updatedDate: Date())
        }
    }

    func resetTagCache() {
        tags = [:]
    }
}
