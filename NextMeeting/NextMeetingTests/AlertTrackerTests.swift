import Foundation
import SwiftUI

private let trackerBase = Date(timeIntervalSince1970: 2_000_000)

private func trackerMeeting(_ title: String, startsAt offset: TimeInterval) -> Meeting {
    Meeting(
        id: title,
        title: title,
        startDate: trackerBase.addingTimeInterval(offset),
        endDate: trackerBase.addingTimeInterval(offset + 1800),
        calendarColor: .blue,
        calendarName: "Work",
        meetingURL: nil
    )
}

/// Whether the policy would still offer `meeting` for an alert.
private func stillEligible(_ meeting: Meeting, _ tracker: MeetingAlertTracker, at now: Date) -> Meeting? {
    MeetingAlertPolicy.meetingToAlert(
        in: [meeting],
        alertedIDs: tracker.alertedIDs,
        alertMinutesBefore: 0,
        now: now
    )
}

func runAlertTrackerTests() {
    print("MeetingAlertTracker")

    runRecordingCases()
    runRetryCases()
    runCleanupCases()
}

private func runRecordingCases() {
    TestRunner.test("a presented alert is recorded") {
        var tracker = MeetingAlertTracker()
        let standup = trackerMeeting("Standup", startsAt: 0)

        let presented = tracker.presentAlert(for: standup, using: { _ in true })

        TestRunner.expect(presented, "expected the alert to be presented")
        TestRunner.expect(tracker.alertedIDs.contains(standup.id), "a shown alert must be recorded")
    }

    // The alert window refuses a second alert while one is still on screen.
    // Recording it anyway would mark it handled and it would never be shown.
    TestRunner.test("a refused alert is not recorded") {
        var tracker = MeetingAlertTracker()
        let standup = trackerMeeting("Standup", startsAt: 0)

        let presented = tracker.presentAlert(for: standup, using: { _ in false })

        TestRunner.expect(!presented, "expected the alert to be refused")
        TestRunner.expect(!tracker.alertedIDs.contains(standup.id),
                          "an alert that never reached the screen must not be recorded")
    }

    TestRunner.test("a shown alert is not presented a second time") {
        var tracker = MeetingAlertTracker()
        let standup = trackerMeeting("Standup", startsAt: 0)
        var presentedCount = 0

        tracker.presentAlert(for: standup, using: { _ in presentedCount += 1; return true })

        TestRunner.expectEqual(presentedCount, 1)
        TestRunner.expect(stillEligible(standup, tracker, at: trackerBase.addingTimeInterval(10)) == nil,
                          "a shown alert must not be offered again")
    }
}

// Consumer-visible outcome: the policy must keep offering a refused meeting so
// the next display tick retries it.
private func runRetryCases() {
    TestRunner.test("a refused alert stays eligible and is shown on retry") {
        var tracker = MeetingAlertTracker()
        let standup = trackerMeeting("Standup", startsAt: 0)
        var presentedCount = 0

        // Another alert is still on screen: refused.
        tracker.presentAlert(for: standup, using: { _ in false })
        TestRunner.expectEqual(stillEligible(standup, tracker, at: trackerBase.addingTimeInterval(10))?.title,
                               "Standup")

        // The earlier alert is dismissed; the retry succeeds.
        tracker.presentAlert(for: standup, using: { _ in presentedCount += 1; return true })
        TestRunner.expectEqual(presentedCount, 1)
        TestRunner.expect(stillEligible(standup, tracker, at: trackerBase.addingTimeInterval(20)) == nil,
                          "a shown alert must not be offered again")
    }
}

private func runCleanupCases() {
    TestRunner.test("ids for meetings no longer fetched are dropped") {
        var tracker = MeetingAlertTracker()
        let standup = trackerMeeting("Standup", startsAt: 0)
        let retro = trackerMeeting("Retro", startsAt: 3600)

        tracker.presentAlert(for: standup, using: { _ in true })
        tracker.presentAlert(for: retro, using: { _ in true })
        tracker.forgetMeetings(notIn: [retro.id])

        TestRunner.expectEqual(tracker.alertedIDs, [retro.id])
    }
}
