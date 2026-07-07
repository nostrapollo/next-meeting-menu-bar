import Foundation
import SwiftUI

struct Meeting: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let calendarColor: Color
    let calendarName: String
    let meetingURL: URL?

    /// Occurrences of a recurring event share one `eventIdentifier`, and some
    /// events (e.g. unsynced Exchange invites) have none at all — combine with
    /// the start date so every occurrence gets a distinct, stable id.
    static func makeID(eventIdentifier: String?, startDate: Date) -> String {
        "\(eventIdentifier ?? "no-identifier")-\(startDate.timeIntervalSince1970)"
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    var timeString: String {
        Self.timeFormatter.string(from: startDate)
    }

    // Time-dependent checks take an explicit `now` so they are deterministic
    // in tests; the parameterless properties are conveniences for views.

    func isHappeningNow(at now: Date = Date()) -> Bool {
        now >= startDate && now <= endDate
    }

    var isHappeningNow: Bool { isHappeningNow() }

    func isJustStarting(at now: Date = Date()) -> Bool {
        let secondsSinceStart = now.timeIntervalSince(startDate)
        return secondsSinceStart >= 0 && secondsSinceStart <= 60
    }

    var isJustStarting: Bool { isJustStarting() }

    func countdownString(at now: Date = Date()) -> String {
        if isHappeningNow(at: now) {
            return "Now"
        }

        let interval = startDate.timeIntervalSince(now)

        if interval < 0 {
            return "Past"
        }

        let minutes = Int(interval / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            if remainingMinutes > 0 {
                return "\(hours)h \(remainingMinutes)m"
            }
            return "\(hours)h"
        }

        if minutes < 1 {
            return "<1m"
        }

        return "\(minutes)m"
    }

    var countdownString: String { countdownString() }

    func menuBarTitle(at now: Date = Date()) -> String {
        let truncatedTitle = title.count > 20 ? String(title.prefix(17)) + "..." : title
        return "\(countdownString(at: now)): \(truncatedTitle)"
    }

    var menuBarTitle: String { menuBarTitle() }
}
