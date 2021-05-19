//
//  Equatable+Group.swift
//  TagTime
//
//  Created by Shawn Koh on 19/5/21.
//

import Foundation

enum Group<Value: Equatable>: Equatable {
    case single(Value)
    case multiple([Value])
}

extension Array where Array.Element: Equatable {
    func grouped() -> [Group<Array.Element>] {
        var result: [Group<Array.Element>] = []
        var cursor = 0
        while cursor < self.count {
            let current = self[cursor]

            // find the next index that is not the same
            var nextIndex = cursor + 1
            while nextIndex < self.count {
                if current == self[nextIndex] {
                    nextIndex += 1
                } else {
                    break
                }
            }

            if nextIndex == cursor + 1 {
                result.append(.single(current))
            } else {
                result.append(.multiple(Array(self[cursor..<nextIndex])))
            }
            cursor = nextIndex
        }
        return result
    }
}
