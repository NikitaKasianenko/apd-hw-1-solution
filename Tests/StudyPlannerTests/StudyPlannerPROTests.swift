import XCTest
@testable import StudyPlanner

final class StudyPlannerPROTests: XCTestCase {

 
    private func makeItem(
        _ id: String,
        title: String = "Task",
        minutes: Int = 10,
        category: StudyCategory = .reading
    ) throws -> StudyItem {
        try StudyItem(id: id, title: title, estimatedMinutes: minutes, category: category)
    }
 
    private func assertPlanError<T>(
        _ expression: @autoclosure () throws -> T,
        _ expected: StudyPlanError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try expression(), file: file, line: line) { error in
            XCTAssertEqual(error as? StudyPlanError, expected, file: file, line: line)
        }
    }
 
    func testMinutesBoundaryRejectsZeroAndNegativeButAcceptsOne() throws {
        assertPlanError(try makeItem("zero", minutes: 0), .nonPositiveEstimatedMinutes)
        assertPlanError(try makeItem("negative", minutes: -1), .nonPositiveEstimatedMinutes)
        XCTAssertEqual(try makeItem("one", minutes: 1).estimatedMinutes, 1)
    }
 
    func testBlankTitleIsReportedBeforeInvalidMinutes() throws {
        assertPlanError(try makeItem("x", title: " \t\n ", minutes: 0), .blankTitle)
 
        // A title with surrounding spaces is not blank and is stored unchanged.
        XCTAssertEqual(try makeItem("y", title: "  Swift  ").title, "  Swift  ")
    }
 
    func testDecodingItemFromJSONRunsValidation() {
        let json = Data("""
        {"id": "x", "title": "   ", "estimatedMinutes": 0, "category": "reading", "isCompleted": false}
        """.utf8)
 
        assertPlanError(try JSONDecoder().decode(StudyItem.self, from: json), .blankTitle)
    }
 
    func testKeyedPlanDecodingReportsFirstDuplicateID() {
        // "a" repeats at index 2, before "b" repeats at index 3.
        let json = Data("""
        {"items": [
          {"id": "a", "title": "A",  "estimatedMinutes": 10, "category": "reading",  "isCompleted": false},
          {"id": "b", "title": "B",  "estimatedMinutes": 10, "category": "practice", "isCompleted": false},
          {"id": "a", "title": "A2", "estimatedMinutes": 10, "category": "reading",  "isCompleted": false},
          {"id": "b", "title": "B2", "estimatedMinutes": 10, "category": "practice", "isCompleted": false}
        ]}
        """.utf8)
 
        assertPlanError(try JSONDecoder().decode(StudyPlan.self, from: json), .duplicateID("a"))
    }
 
    func testFixtureArrayDecodesSortedWithCorrectQueries() throws {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "study-items", withExtension: "json", subdirectory: "Fixtures")
        )
        let plan = try StudyPlan.decode(from: Data(contentsOf: url))
 
        XCTAssertEqual(plan.items.map(\.id), ["planner-milestone", "collections-drill", "swift-chapter-1"])

        XCTAssertEqual(plan.incompleteMinutes(), 135)
        XCTAssertEqual(plan.items(in: .practice).map(\.id), ["collections-drill"])
    }
 
 
    func testOrderingIsTitleThenIDRegardlessOfInputOrder() throws {
        let a = try makeItem("a", title: "Swift")
        let b = try makeItem("b", title: "Swift")
        let c = try makeItem("c", title: "Algebra")
 
        let first = try StudyPlan(items: [b, a, c])
        let second = try StudyPlan(items: [c, a, b])
 
        XCTAssertEqual(first.items.map(\.id), ["c", "a", "b"])
        XCTAssertEqual(first, second)
    }
 
    
    func testMarkCompletedIsIdempotentAndRejectsUnknownID() throws {
        var plan = try StudyPlan(items: [makeItem("a", minutes: 10), makeItem("b", minutes: 25)])
 
        try plan.markCompleted(id: "a")
        let afterFirstCompletion = plan
 
        XCTAssertNoThrow(try plan.markCompleted(id: "a"))
        XCTAssertEqual(plan, afterFirstCompletion)
        XCTAssertEqual(plan.incompleteMinutes(), 25)
 
        assertPlanError(try plan.markCompleted(id: "missing"), .unknownID("missing"))
        XCTAssertEqual(plan, afterFirstCompletion)
    }
    
    // MARK: - Bonus
    func testImportMergingReplacesInPlaceAndAppendsNewItemsByID() throws {
        var plan = try StudyPlan(items: [
            makeItem("b", title: "Old B"),
            makeItem("d", title: "Old D")
        ])

        try plan.importMerging([
            makeItem("z", title: "Z"),
            makeItem("d", title: "New D"),
            makeItem("a", title: "A")
        ])

        XCTAssertEqual(plan.items.map(\.id), ["b", "d", "a", "z"])
        XCTAssertEqual(plan.items[1].title, "New D")
        XCTAssertEqual(plan.items[0].title, "Old B")
    }

    func testImportMergingWithDuplicateIDsThrowsAndLeavesPlanUnchanged() throws {
        var plan = try StudyPlan(items: [
            makeItem("b", title: "Old B"),
            makeItem("d", title: "Old D")
        ])
        let before = plan

        assertPlanError(
            try plan.importMerging([
                makeItem("x", title: "X"),
                makeItem("d", title: "New D"),
                makeItem("x", title: "X again")
            ]),
            .duplicateID("x")
        )

        XCTAssertEqual(plan, before)
    }

    func testImportMergingWithEmptyArrayChangesNothing() throws {
        var plan = try StudyPlan(items: [makeItem("a"), makeItem("b")])
        let before = plan

        try plan.importMerging([])

        XCTAssertEqual(plan, before)
    }

 
}
