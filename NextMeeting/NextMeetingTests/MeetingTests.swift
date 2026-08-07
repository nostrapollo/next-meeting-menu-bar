import Foundation
import SwiftUI

/// All time-dependent behavior is exercised against a fixed reference date so
/// results don't depend on when the tests run.
private let meetingNow = Date(timeIntervalSince1970: 1_750_000_000)

private func makeMeeting(
    id: String = "test-id",
    title: String = "Test Meeting",
    startOffset: TimeInterval = 900,
    endOffset: TimeInterval = 4500,
    meetingURL: URL? = nil
) -> Meeting {
    Meeting(
        id: id,
        title: title,
        startDate: meetingNow.addingTimeInterval(startOffset),
        endDate: meetingNow.addingTimeInterval(endOffset),
        calendarColor: .blue,
        calendarName: "Test Calendar",
        meetingURL: meetingURL
    )
}

func runMeetingTests() {
    print("Meeting")

    runCountdownStringCases()
    runIsHappeningNowCases()
    runIsJustStartingCases()
    runMenuBarTitleCases()
    runMakeIDCases()
}

// MARK: countdownString

private func runCountdownStringCases() {
    let now = meetingNow

    TestRunner.test("countdown is Now during the meeting") {
        let meeting = makeMeeting(startOffset: -30, endOffset: 1800)
        TestRunner.expectEqual(meeting.countdownString(at: now), "Now")
    }

    TestRunner.test("countdown is Past after the meeting ended") {
        let meeting = makeMeeting(startOffset: -7200, endOffset: -3600)
        TestRunner.expectEqual(meeting.countdownString(at: now), "Past")
    }

    TestRunner.test("countdown shows minutes") {
        let meeting = makeMeeting(startOffset: 900, endOffset: 4500)
        TestRunner.expectEqual(meeting.countdownString(at: now), "15m")
    }

    TestRunner.test("countdown shows hours and minutes") {
        let meeting = makeMeeting(startOffset: 5400, endOffset: 9000)
        TestRunner.expectEqual(meeting.countdownString(at: now), "1h 30m")
    }

    TestRunner.test("countdown shows whole hours without minutes") {
        let meeting = makeMeeting(startOffset: 7200, endOffset: 10800)
        TestRunner.expectEqual(meeting.countdownString(at: now), "2h")
    }

    TestRunner.test("countdown shows <1m just before start") {
        let meeting = makeMeeting(startOffset: 30, endOffset: 3630)
        TestRunner.expectEqual(meeting.countdownString(at: now), "<1m")
    }
}

// MARK: isHappeningNow

private func runIsHappeningNowCases() {
    let now = meetingNow

    TestRunner.test("isHappeningNow true mid-meeting") {
        let meeting = makeMeeting(startOffset: -300, endOffset: 1500)
        TestRunner.expect(meeting.isHappeningNow(at: now))
    }

    TestRunner.test("isHappeningNow false before start") {
        let meeting = makeMeeting(startOffset: 300, endOffset: 3900)
        TestRunner.expect(!meeting.isHappeningNow(at: now))
    }

    TestRunner.test("isHappeningNow false after end") {
        let meeting = makeMeeting(startOffset: -3600, endOffset: -300)
        TestRunner.expect(!meeting.isHappeningNow(at: now))
    }
}

// MARK: isJustStarting

private func runIsJustStartingCases() {
    let now = meetingNow

    TestRunner.test("isJustStarting true within 60s of start") {
        let meeting = makeMeeting(startOffset: -30, endOffset: 3570)
        TestRunner.expect(meeting.isJustStarting(at: now))
    }

    TestRunner.test("isJustStarting false after 60s") {
        let meeting = makeMeeting(startOffset: -120, endOffset: 3480)
        TestRunner.expect(!meeting.isJustStarting(at: now))
    }

    TestRunner.test("isJustStarting false before start") {
        let meeting = makeMeeting(startOffset: 30, endOffset: 3630)
        TestRunner.expect(!meeting.isJustStarting(at: now))
    }
}

// MARK: menuBarTitle

private func runMenuBarTitleCases() {
    let now = meetingNow

    TestRunner.test("short title is not truncated") {
        let meeting = makeMeeting(title: "Team Standup")
        TestRunner.expect(meeting.menuBarTitle(at: now).contains("Team Standup"))
    }

    TestRunner.test("long title is truncated with ellipsis") {
        let meeting = makeMeeting(title: "Very Long Meeting Title That Should Be Truncated")
        let title = meeting.menuBarTitle(at: now)
        TestRunner.expect(title.contains("..."), "expected ellipsis in \(title)")
        TestRunner.expect(title.count <= 30, "title too long: \(title)")
    }
}

// MARK: makeID

private func runMakeIDCases() {
    let now = meetingNow

    TestRunner.test("makeID distinguishes occurrences of a recurring event") {
        let first = Meeting.makeID(eventIdentifier: "recurring-standup", startDate: now)
        let second = Meeting.makeID(eventIdentifier: "recurring-standup", startDate: now.addingTimeInterval(86400))
        TestRunner.expect(first != second, "occurrences must not share an id")
    }

    TestRunner.test("makeID is stable for the same occurrence") {
        let first = Meeting.makeID(eventIdentifier: "abc", startDate: now)
        let second = Meeting.makeID(eventIdentifier: "abc", startDate: now)
        TestRunner.expectEqual(first, second)
    }

    TestRunner.test("makeID tolerates a nil event identifier") {
        let id = Meeting.makeID(eventIdentifier: nil, startDate: now)
        TestRunner.expect(!id.isEmpty)
    }
}
