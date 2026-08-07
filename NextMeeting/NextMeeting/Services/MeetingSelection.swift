import Foundation

/// Picks the meeting to display and act on from a start-date-sorted list.
/// Pure logic with an injectable clock so it can be unit tested directly.
enum MeetingSelection {

    /// The meeting happening right now, if any.
    static func current(in meetings: [Meeting], at now: Date) -> Meeting? {
        meetings.first { $0.isHappeningNow(at: now) }
    }

    /// The next meeting that has not started yet.
    ///
    /// Meetings that have already ended are excluded. The fetched list is only
    /// refreshed on the refresh interval (up to five minutes) while `now`
    /// advances every second, so a finished meeting lingers in the list —
    /// testing "not happening now" would report it as the next meeting.
    static func next(in meetings: [Meeting], at now: Date) -> Meeting? {
        meetings.first { $0.startDate > now }
    }
}
