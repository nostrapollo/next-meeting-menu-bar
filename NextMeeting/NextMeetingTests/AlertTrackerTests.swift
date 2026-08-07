import Foundation
import SwiftUI

func runAlertTrackerTests() {
    print("MeetingAlertTracker")

    let base = Date(timeIntervalSince1970: 2_000_000)

    func meeting(_ title: String, startsAt offset: TimeInterval) -> Meeting {
        Meeting(
            id: title,
            title: title,
            startDate: base.addingTimeInterval(offset),
            endDate: base.addingTimeInterval(offset + 1800),
            calendarColor: .blue,
            calendarName: "Work",
            meetingURL: nil
        )
    }

    TestRunner.test("a presented alert is recorded") {
        var tracker = MeetingAlertTracker()
        let standup = meeting("Standup", startsAt: 0)

        let presented = tracker.presentAlert(for: standup, using: { _ in true })

        TestRunner.expect(presented, "expected the alert to be presented")
        TestRunner.expect(tracker.alertedIDs.contains(standup.id), "a shown alert must be recorded")
    }

    // The alert window refuses a second alert while one is still on screen.
    // Recording it anyway would mark it handled and it would never be shown.
    TestRunner.test("a refused alert is not recorded") {
        var tracker = MeetingAlertTracker()
        let standup = meeting("Standup", startsAt: 0)

        let presented = tracker.presentAlert(for: standup, using: { _ in false })

        TestRunner.expect(!presented, "expected the alert to be refused")
        TestRunner.expect(!tracker.alertedIDs.contains(standup.id),
                          "an alert that never reached the screen must not be recorded")
    }

    // Consumer-visible outcome: the policy must keep offering the meeting so
    // the next display tick retries it.
    TestRunner.test("a refused alert stays eligible and is shown on retry") {
        var tracker = MeetingAlertTracker()
        let standup = meeting("Standup", startsAt: 0)
        let meetings = [standup]
        var presentedCount = 0

        // Another alert is still on screen: refused.
        tracker.presentAlert(for: standup, using: { _ in false })

        let stillEligible = MeetingAlertPolicy.meetingToAlert(
            in: meetings,
            alertedIDs: tracker.alertedIDs,
            alertMinutesBefore: 0,
            now: base.addingTimeInterval(10)
        )
        TestRunner.expectEqual(stillEligible?.title, "Standup")

        // The earlier alert is dismissed; the retry succeeds.
        tracker.presentAlert(for: standup, using: { _ in presentedCount += 1; return true })
        TestRunner.expectEqual(presentedCount, 1)

        let afterShowing = MeetingAlertPolicy.meetingToAlert(
            in: meetings,
            alertedIDs: tracker.alertedIDs,
            alertMinutesBefore: 0,
            now: base.addingTimeInterval(20)
        )
        TestRunner.expect(afterShowing == nil, "a shown alert must not be offered again")
    }

    TestRunner.test("a shown alert is not presented a second time") {
        var tracker = MeetingAlertTracker()
        let standup = meeting("Standup", startsAt: 0)
        var presentedCount = 0

        tracker.presentAlert(for: standup, using: { _ in presentedCount += 1; return true })

        let stillEligible = MeetingAlertPolicy.meetingToAlert(
            in: [standup],
            alertedIDs: tracker.alertedIDs,
            alertMinutesBefore: 0,
            now: base.addingTimeInterval(10)
        )

        TestRunner.expectEqual(presentedCount, 1)
        TestRunner.expect(stillEligible == nil, "a shown alert must not be offered again")
    }

    TestRunner.test("ids for meetings no longer fetched are dropped") {
        var tracker = MeetingAlertTracker()
        let standup = meeting("Standup", startsAt: 0)
        let retro = meeting("Retro", startsAt: 3600)

        tracker.presentAlert(for: standup, using: { _ in true })
        tracker.presentAlert(for: retro, using: { _ in true })
        tracker.forgetMeetings(notIn: [retro.id])

        TestRunner.expectEqual(tracker.alertedIDs, [retro.id])
    }
}
