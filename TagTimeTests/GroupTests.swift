//
//  Logbook.swift
//  TagTimeTests
//
//  Created by Shawn Koh on 19/5/21.
//

import XCTest

class GroupTests: XCTestCase {
    func test() {
        let input: [String] = []
        let output: [Group<String>] = []
        XCTAssert(input.grouped() == output)

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

    private func test(input: String..., expected: Group<String>...) {
        let result = input.grouped()
        XCTAssert(result == expected)
    }

    private func single(_ input: String) -> Group<String> {
        .single(input)
    }

    private func multiple(_ input: String...) -> Group<String> {
        .multiple(input)
    }
}
