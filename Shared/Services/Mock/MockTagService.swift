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
    func registerTags(_ tags: [Tag], with batch: WriteBatch?, increment: Int) {
        tags.forEach { tag in
            if let tagCache = self.tags[tag] {
                self.tags[tag] = TagCache(count: tagCache.count + increment, updatedDate: Date())
            } else {
                self.tags[tag] = TagCache(count: increment, updatedDate: Date())
            }
        }
    }

    // Actually why do we even need to have a decrement function? It's still + anyway
    // TODO: Replace this function. It's not necessary, all we need to do is just add min(0, tagCache.count + increment) in registerTags
    func deregisterTags(_ tags: [Tag], with batch: WriteBatch?, decrement: Int) {
        tags.forEach { tag in
            guard let tagCache = self.tags[tag] else {
                return
            }
            self.tags[tag] = TagCache(count: min(0, tagCache.count + decrement), updatedDate: Date())
        }
    }

    func resetTagCache() {
        tags = [:]
    }
}
