//
//  Equatable+Group.swift
//  TagTime
//
//  Created by Shawn Koh on 19/5/21.
//

import Foundation

enum Group<Value: Equatable & Hashable>: Equatable, Hashable {
    case single(Value)
    case multiple([Value])
}

extension Array where Array.Element: Equatable & Hashable {
    func grouped() -> [Group<Array.Element>] {
        grouped { $0 == $1 }
    }

    func grouped(by areTheSame: (Array.Element, Array.Element) -> Bool ) -> [Group<Array.Element>] {
        var result: [Group<Array.Element>] = []
        var cursor = 0
        while cursor < self.count {
            let current = self[cursor]

            // find the next index that is not the same
            var nextIndex = cursor + 1
            while nextIndex < self.count {
                if areTheSame(current, self[nextIndex]) {
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
