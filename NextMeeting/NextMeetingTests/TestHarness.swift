import Foundation

/// Minimal test harness. XCTest ships only with full Xcode, and this project
/// builds with the Command Line Tools alone, so tests compile into a plain
/// executable (see test.sh) using these assertion helpers.
enum TestRunner {
    private(set) static var passed = 0
    private(set) static var failed = 0
    private static var currentTest = ""

    static func test(_ name: String, _ body: () -> Void) {
        currentTest = name
        let failuresBefore = failed
        body()
        if failed == failuresBefore {
            print("  ✓ \(name)")
        }
    }

    static func expect(_ condition: Bool,
                       _ message: String = "expected true",
                       file: StaticString = #filePath,
                       line: UInt = #line) {
        if condition {
            passed += 1
        } else {
            failed += 1
            print("  ✗ \(currentTest) — \(message) (\(file):\(line))")
        }
    }

    static func expectEqual<T: Equatable>(_ actual: T,
                                          _ expected: T,
                                          file: StaticString = #filePath,
                                          line: UInt = #line) {
        expect(actual == expected, "expected \(expected), got \(actual)", file: file, line: line)
    }

    static func finish() -> Never {
        print("\n\(passed) assertions passed, \(failed) failed")
        exit(failed == 0 ? 0 : 1)
    }
}
