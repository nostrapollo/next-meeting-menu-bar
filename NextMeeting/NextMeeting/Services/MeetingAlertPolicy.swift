import Foundation

/// Decides which meeting (if any) deserves a full-screen alert right now.
/// Pure logic with an injectable clock so it can be unit tested; the caller
/// evaluates it on a frequent tick so the alert window is never skipped.
enum MeetingAlertPolicy {

    /// - Parameters:
    ///   - meetings: upcoming meetings, sorted by start date.
    ///   - alertedIDs: meetings that have already shown an alert.
    ///   - alertMinutesBefore: 0 means "at start"; N means "N minutes before start".
    static func meetingToAlert(
        in meetings: [Meeting],
        alertedIDs: Set<String>,
        alertMinutesBefore: Int,
        now: Date = Date()
    ) -> Meeting? {
        meetings.first { meeting in
            guard !alertedIDs.contains(meeting.id) else { return false }

            if alertMinutesBefore == 0 {
                // At start: within the first 60 seconds after the meeting begins.
                return meeting.isJustStarting(at: now)
            }

            // Before start: inside the one-minute window ending at the alert time,
            // e.g. for "5 minutes before" fire while 4-5 minutes remain.
            let minutesUntilStart = meeting.startDate.timeIntervalSince(now) / 60
            return minutesUntilStart >= Double(alertMinutesBefore - 1)
                && minutesUntilStart <= Double(alertMinutesBefore)
        }
    }
}
