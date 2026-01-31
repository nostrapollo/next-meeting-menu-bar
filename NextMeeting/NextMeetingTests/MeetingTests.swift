import XCTest
import SwiftUI
@testable import NextMeeting

final class MeetingTests: XCTestCase {
    
    // MARK: - Countdown String Tests
    
    func testCountdownString_whenMeetingIsNow_returnsNow() {
        let meeting = createMeeting(
            startDate: Date().addingTimeInterval(-30),  // Started 30 seconds ago
            endDate: Date().addingTimeInterval(1800)    // Ends in 30 minutes
        )
        XCTAssertEqual(meeting.countdownString, "Now")
    }
    
    func testCountdownString_whenMeetingIsPast_returnsPast() {
        let meeting = createMeeting(
            startDate: Date().addingTimeInterval(-7200),  // Started 2 hours ago
            endDate: Date().addingTimeInterval(-3600)     // Ended 1 hour ago
        )
        XCTAssertEqual(meeting.countdownString, "Past")
    }
    
    func testCountdownString_whenMeetingInMinutes_returnsMinutes() {
        let meeting = createMeeting(
            startDate: Date().addingTimeInterval(900),   // Starts in 15 minutes
            endDate: Date().addingTimeInterval(4500)     // Ends in 75 minutes
        )
        XCTAssertEqual(meeting.countdownString, "15m")
    }
    
    func testCountdownString_whenMeetingInHours_returnsHoursAndMinutes() {
        let meeting = createMeeting(
            startDate: Date().addingTimeInterval(5400),  // Starts in 1.5 hours
            endDate: Date().addingTimeInterval(9000)
        )
        XCTAssertEqual(meeting.countdownString, "1h 30m")
    }
    
    func testCountdownString_whenMeetingInExactHours_returnsHoursOnly() {
        let meeting = createMeeting(
            startDate: Date().addingTimeInterval(7200),  // Starts in 2 hours
            endDate: Date().addingTimeInterval(10800)
        )
        XCTAssertEqual(meeting.countdownString, "2h")
    }
    
    func testCountdownString_whenLessThanOneMinute_returnsLessThanOneMinute() {
        let meeting = createMeeting(
            startDate: Date().addingTimeInterval(30),    // Starts in 30 seconds
            endDate: Date().addingTimeInterval(3630)
        )
        XCTAssertEqual(meeting.countdownString, "<1m")
    }
    
    // MARK: - isHappeningNow Tests
    
    func testIsHappeningNow_whenCurrentlyInMeeting_returnsTrue() {
        let meeting = createMeeting(
            startDate: Date().addingTimeInterval(-300),  // Started 5 minutes ago
            endDate: Date().addingTimeInterval(1500)     // Ends in 25 minutes
        )
        XCTAssertTrue(meeting.isHappeningNow)
    }
    
    func testIsHappeningNow_whenMeetingNotStarted_returnsFalse() {
        let meeting = createMeeting(
            startDate: Date().addingTimeInterval(300),   // Starts in 5 minutes
            endDate: Date().addingTimeInterval(3900)
        )
        XCTAssertFalse(meeting.isHappeningNow)
    }
    
    func testIsHappeningNow_whenMeetingEnded_returnsFalse() {
        let meeting = createMeeting(
            startDate: Date().addingTimeInterval(-3600), // Started 1 hour ago
            endDate: Date().addingTimeInterval(-300)     // Ended 5 minutes ago
        )
        XCTAssertFalse(meeting.isHappeningNow)
    }
    
    // MARK: - isJustStarting Tests
    
    func testIsJustStarting_whenWithin60Seconds_returnsTrue() {
        let meeting = createMeeting(
            startDate: Date().addingTimeInterval(-30),   // Started 30 seconds ago
            endDate: Date().addingTimeInterval(3570)
        )
        XCTAssertTrue(meeting.isJustStarting)
    }
    
    func testIsJustStarting_whenOver60Seconds_returnsFalse() {
        let meeting = createMeeting(
            startDate: Date().addingTimeInterval(-120),  // Started 2 minutes ago
            endDate: Date().addingTimeInterval(3480)
        )
        XCTAssertFalse(meeting.isJustStarting)
    }
    
    // MARK: - Menu Bar Title Tests
    
    func testMenuBarTitle_shortTitle_notTruncated() {
        let meeting = createMeeting(title: "Team Standup")
        XCTAssertTrue(meeting.menuBarTitle.contains("Team Standup"))
    }
    
    func testMenuBarTitle_longTitle_truncatedWithEllipsis() {
        let meeting = createMeeting(title: "Very Long Meeting Title That Should Be Truncated")
        XCTAssertTrue(meeting.menuBarTitle.contains("..."))
        XCTAssertLessThanOrEqual(meeting.menuBarTitle.count, 30) // countdown + truncated title
    }
    
    // MARK: - Helper
    
    private func createMeeting(
        id: String = "test-id",
        title: String = "Test Meeting",
        startDate: Date = Date().addingTimeInterval(900),
        endDate: Date = Date().addingTimeInterval(4500),
        meetingURL: URL? = nil
    ) -> Meeting {
        Meeting(
            id: id,
            title: title,
            startDate: startDate,
            endDate: endDate,
            calendarColor: .blue,
            calendarName: "Test Calendar",
            meetingURL: meetingURL
        )
    }
}
