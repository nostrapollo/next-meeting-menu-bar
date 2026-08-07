import Foundation

/// Records which meetings have already shown a full-screen alert, so the alert
/// policy stops offering them. Pure logic — the actual presentation is injected
/// — so it can be unit tested directly.
struct MeetingAlertTracker {

    private(set) var alertedIDs: Set<String> = []

    /// Presents the alert, recording the meeting only if it reached the screen.
    ///
    /// Recording on the attempt instead would permanently suppress a meeting
    /// whose alert was refused because an earlier alert was still on screen:
    /// the policy would treat it as handled and never offer it again.
    ///
    /// - Parameter present: shows the alert; returns `false` if it could not be
    ///   shown right now.
    /// - Returns: whether the alert reached the screen.
    @discardableResult
    mutating func presentAlert(for meeting: Meeting, using present: (Meeting) -> Bool) -> Bool {
        guard present(meeting) else { return false }
        alertedIDs.insert(meeting.id)
        return true
    }

    /// Drops recorded ids for meetings that are no longer in the fetched list.
    mutating func forgetMeetings(notIn currentIDs: Set<String>) {
        alertedIDs.formIntersection(currentIDs)
    }
}
