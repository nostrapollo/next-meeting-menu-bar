import Foundation
import SwiftUI

func runMeetingSelectionTests() {
    print("MeetingSelection")

    let base = Date(timeIntervalSince1970: 1_000_000)

    func meeting(_ title: String, startsAt offset: TimeInterval, lasting duration: TimeInterval) -> Meeting {
        Meeting(
            id: title,
            title: title,
            startDate: base.addingTimeInterval(offset),
            endDate: base.addingTimeInterval(offset + duration),
            calendarColor: .blue,
            calendarName: "Work",
            meetingURL: URL(string: "https://meet.google.com/\(title)")
        )
    }

    // The fetched list is only refreshed on the refresh interval (up to 5
    // minutes), so a meeting that has already ended lingers in it. It must
    // never be reported as the next meeting.
    TestRunner.test("next skips a meeting that has already ended") {
        let ended = meeting("Standup", startsAt: 0, lasting: 300)
        let upcoming = meeting("Retro", startsAt: 3600, lasting: 1800)
        let now = base.addingTimeInterval(400)

        TestRunner.expectEqual(MeetingSelection.next(in: [ended, upcoming], at: now)?.title, "Retro")
    }

    TestRunner.test("next is nil when every meeting has ended") {
        let ended = meeting("Standup", startsAt: 0, lasting: 300)
        let now = base.addingTimeInterval(400)

        TestRunner.expect(MeetingSelection.next(in: [ended], at: now) == nil,
                          "expected nil, got \(MeetingSelection.next(in: [ended], at: now)?.title ?? "nil")")
    }

    // Regression: an ended meeting used to win over the live one, so the menu
    // bar read "Past: Standup" while the all-hands was in progress.
    TestRunner.test("menu bar falls back to the live meeting, not an ended one") {
        let ended = meeting("Standup", startsAt: 0, lasting: 300)
        let live = meeting("AllHands", startsAt: 240, lasting: 3600)
        let now = base.addingTimeInterval(400)
        let meetings = [ended, live]

        let displayed = MeetingSelection.next(in: meetings, at: now) ?? MeetingSelection.current(in: meetings, at: now)
        TestRunner.expectEqual(displayed?.menuBarTitle(at: now), "Now: AllHands")
    }

    // The hotkey joins `current ?? next`; with no live meeting it must not open
    // the URL of a meeting that finished minutes ago.
    TestRunner.test("hotkey target is nil rather than an ended meeting") {
        let ended = meeting("Standup", startsAt: 0, lasting: 300)
        let now = base.addingTimeInterval(400)
        let meetings = [ended]

        let target = MeetingSelection.current(in: meetings, at: now) ?? MeetingSelection.next(in: meetings, at: now)
        TestRunner.expect(target == nil, "expected no join target, got \(target?.title ?? "nil")")
    }

    TestRunner.test("current returns the in-progress meeting") {
        let live = meeting("AllHands", startsAt: 240, lasting: 3600)
        let now = base.addingTimeInterval(400)

        TestRunner.expectEqual(MeetingSelection.current(in: [live], at: now)?.title, "AllHands")
    }

    // A meeting starting on this exact second counts as current, so `next`
    // must exclude it — otherwise both would report the same meeting.
    TestRunner.test("a meeting starting exactly now is current, not next") {
        let starting = meeting("Sync", startsAt: 0, lasting: 1800)

        TestRunner.expectEqual(MeetingSelection.current(in: [starting], at: base)?.title, "Sync")
        TestRunner.expect(MeetingSelection.next(in: [starting], at: base) == nil,
                          "a meeting starting now must not also be the next meeting")
    }

    TestRunner.test("next returns the earliest future meeting") {
        let soon = meeting("Retro", startsAt: 600, lasting: 1800)
        let later = meeting("1:1", startsAt: 7200, lasting: 1800)

        TestRunner.expectEqual(MeetingSelection.next(in: [soon, later], at: base)?.title, "Retro")
    }
}
