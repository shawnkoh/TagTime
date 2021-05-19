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

        test(input: "A", "A", expected: multiple("B", "B"))
        test(input: "A", "B", expected: single("A"), single("B"))

        test(input: "A", "A", "B", expected: multiple("A", "A"), single("B"))
        test(input: "A", "B", "B", expected: single("A"), multiple("B", "B"))

        test(input: "A", "A", "B", "B", expected: multiple("A", "A"), multiple("B", "B"))
        test(input: "A", "B", "A", "B", expected: single("A"), single("B"), single("A"), single("B"))
        test(input: "A", "A", "A", "B", expected: multiple("A", "A", "A"), single("B"))
        test(input: "A", "B", "B", "B", expected: single("A"), multiple("B", "B", "B"))
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
        guard let first = input.first else {
            return []
        }
        var cursor = first
        var result: [Row] = []
        var multiple: [String] = []
        return []
    }
}
