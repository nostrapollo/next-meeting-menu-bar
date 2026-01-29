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

    var isHappeningNow: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }

    var countdownString: String {
        let now = Date()

        if isHappeningNow {
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

    var menuBarTitle: String {
        let truncatedTitle = title.count > 20 ? String(title.prefix(17)) + "..." : title
        return "\(countdownString): \(truncatedTitle)"
    }
}
