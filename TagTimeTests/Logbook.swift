//
//  Logbook.swift
//  TagTimeTests
//
//  Created by Shawn Koh on 19/5/21.
//

import XCTest

private enum Row: Equatable {
    case single(String)
    case multiple([String])
}

class Logbook: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testBlah() {
        XCTAssert(row([]) == [])

        test(input: "A", expected: single("A"))

        test(input: "A", "A", expected: multiple("A", "A"))
        test(input: "A", "B", expected: single("A"), single("B"))

        test(input: "A", "A", "A", expected: multiple("A", "A", "A"))
        test(input: "A", "A", "B", expected: multiple("A", "A"), single("B"))
        test(input: "A", "B", "B", expected: single("A"), multiple("B", "B"))
        test(input: "A", "B", "C", expected: single("A"), single("B"), single("C"))

        test(input: "A", "A", "B", "B", expected: multiple("A", "A"), multiple("B", "B"))
        test(input: "A", "B", "A", "B", expected: single("A"), single("B"), single("A"), single("B"))
        test(input: "A", "A", "A", "B", expected: multiple("A", "A", "A"), single("B"))
        test(input: "A", "B", "B", "B", expected: single("A"), multiple("B", "B", "B"))
        test(input: "A", "B", "C", "D", expected: single("A"), single("B"), single("C"), single("D"))
    }

    private func test(input: String..., expected: Row...) {
        let result = row(input)
        XCTAssert(result == expected)
    }

    private func single(_ input: String) -> Row {
        .single(input)
    }

    private func multiple(_ input: String...) -> Row {
        .multiple(input)
    }

    private func row(_ input: [String]) -> [Row] {
        var result: [Row] = []
        var cursor = 0
        while cursor < input.count {
            let current = input[cursor]

            // find the next index that is not the same
            var nextIndex = cursor + 1
            while nextIndex < input.count {
                if current == input[nextIndex] {
                    nextIndex += 1
                } else {
                    break
                }
            }

            if nextIndex == cursor + 1 {
                result.append(.single(current))
            } else {
                result.append(.multiple(Array(input[cursor..<nextIndex])))
            }
            cursor = nextIndex
        }
        return result
    }
}
