import Foundation
import SwiftUI

func runPineTimeTests() {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    func event(_ title: String, _ start: TimeInterval, _ end: TimeInterval) -> Meeting {
        Meeting(id: title, title: title, startDate: now.addingTimeInterval(start),
                endDate: now.addingTimeInterval(end), calendarColor: .blue, calendarName: "Test", meetingURL: nil)
    }
    TestRunner.test("watch follows upcoming meeting before current meeting") {
        let result = PineTimeRelay.Payload.next(in: [event("Current", -60, 120), event("Next", 300, 600)], now: now)
        TestRunner.expectEqual(result.title, "Next")
        TestRunner.expectEqual(result.startEpoch, 1_800_000_300)
    }
    TestRunner.test("watch retains current meeting when nothing upcoming") {
        let result = PineTimeRelay.Payload.next(in: [event("Current", -60, 120)], now: now)
        TestRunner.expectEqual(result.title, "Current")
    }
    TestRunner.test("watch clears at event end and with empty calendar") {
        TestRunner.expectEqual(PineTimeRelay.Payload.next(in: [event("Past", -60, 0)], now: now).clear, true)
        TestRunner.expectEqual(PineTimeRelay.Payload.next(in: [], now: now).clear, true)
    }
    TestRunner.test("watch payload does not change every countdown tick") {
        let events = [event("Next", 300, 600)]
        TestRunner.expectEqual(PineTimeRelay.Payload.next(in: events, now: now),
                               PineTimeRelay.Payload.next(in: events, now: now.addingTimeInterval(1)))
    }
}
