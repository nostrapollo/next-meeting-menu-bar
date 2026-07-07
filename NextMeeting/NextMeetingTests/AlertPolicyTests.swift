import Foundation
import SwiftUI

func runAlertPolicyTests() {
    print("MeetingAlertPolicy")
    let now = Date(timeIntervalSince1970: 1_750_000_000)

    func makeMeeting(id: String, startOffset: TimeInterval) -> Meeting {
        Meeting(
            id: id,
            title: "Meeting \(id)",
            startDate: now.addingTimeInterval(startOffset),
            endDate: now.addingTimeInterval(startOffset + 1800),
            calendarColor: .blue,
            calendarName: "Test Calendar",
            meetingURL: nil
        )
    }

    func alert(_ meetings: [Meeting],
               alerted: Set<String> = [],
               minutesBefore: Int,
               at date: Date) -> Meeting? {
        MeetingAlertPolicy.meetingToAlert(
            in: meetings,
            alertedIDs: alerted,
            alertMinutesBefore: minutesBefore,
            now: date
        )
    }

    // MARK: "At start" (0 minutes before)

    TestRunner.test("at-start alerts within 60s after start") {
        let meeting = makeMeeting(id: "a", startOffset: -30)
        TestRunner.expectEqual(alert([meeting], minutesBefore: 0, at: now)?.id, "a")
    }

    TestRunner.test("at-start does not alert before start") {
        let meeting = makeMeeting(id: "a", startOffset: 30)
        TestRunner.expect(alert([meeting], minutesBefore: 0, at: now) == nil)
    }

    TestRunner.test("at-start does not alert more than 60s after start") {
        let meeting = makeMeeting(id: "a", startOffset: -90)
        TestRunner.expect(alert([meeting], minutesBefore: 0, at: now) == nil)
    }

    // MARK: "N minutes before"

    TestRunner.test("5-min-before alerts inside the 4-5 minute window") {
        let meeting = makeMeeting(id: "a", startOffset: 270) // 4.5 minutes out
        TestRunner.expectEqual(alert([meeting], minutesBefore: 5, at: now)?.id, "a")
    }

    TestRunner.test("5-min-before stays quiet outside the window") {
        let early = makeMeeting(id: "a", startOffset: 330) // 5.5 minutes out
        TestRunner.expect(alert([early], minutesBefore: 5, at: now) == nil)
        let late = makeMeeting(id: "b", startOffset: 230)  // window already passed
        TestRunner.expect(alert([late], minutesBefore: 5, at: now) == nil)
    }

    TestRunner.test("second-by-second evaluation catches the window a slow fetch would skip") {
        // The old implementation only checked on the refresh tick; with a
        // 5-minute interval a 60-second window could fall entirely between
        // ticks. Evaluating every second, at least one tick lands inside.
        let meeting = makeMeeting(id: "a", startOffset: 300)
        let hits = (0...300).filter { second in
            alert([meeting], minutesBefore: 5, at: now.addingTimeInterval(TimeInterval(second))) != nil
        }
        TestRunner.expect(hits.count >= 60, "expected ~60 eligible seconds, got \(hits.count)")
    }

    // MARK: Deduplication

    TestRunner.test("already-alerted meetings are skipped") {
        let meeting = makeMeeting(id: "a", startOffset: -30)
        TestRunner.expect(alert([meeting], alerted: ["a"], minutesBefore: 0, at: now) == nil)
    }

    TestRunner.test("alerting one occurrence does not suppress the next one") {
        let today = makeMeeting(id: Meeting.makeID(eventIdentifier: "standup", startDate: now), startOffset: -30)
        let tomorrowStart = now.addingTimeInterval(86400)
        let tomorrow = Meeting(
            id: Meeting.makeID(eventIdentifier: "standup", startDate: tomorrowStart),
            title: "Standup",
            startDate: tomorrowStart,
            endDate: tomorrowStart.addingTimeInterval(1800),
            calendarColor: .blue,
            calendarName: "Test Calendar",
            meetingURL: nil
        )

        let alerted: Set<String> = [today.id]
        let result = alert([today, tomorrow], alerted: alerted, minutesBefore: 0,
                           at: tomorrowStart.addingTimeInterval(10))
        TestRunner.expectEqual(result?.id, tomorrow.id)
    }

    TestRunner.test("first eligible meeting wins when several qualify") {
        let first = makeMeeting(id: "a", startOffset: -10)
        let second = makeMeeting(id: "b", startOffset: -20)
        TestRunner.expectEqual(alert([first, second], minutesBefore: 0, at: now)?.id, "a")
    }
}
