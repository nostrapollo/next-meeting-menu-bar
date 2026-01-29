import SwiftUI

@main
struct NextMeetingApp: App {
    @StateObject private var calendarService = CalendarService()
    @State private var refreshTimer: Timer?

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(calendarService: calendarService)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                Text(menuBarTitle)
            }
        }
        .menuBarExtraStyle(.window)
        .onChange(of: calendarService.hasAccess) { newValue in
            if newValue {
                startRefreshTimer()
            }
        }
    }

    private var menuBarTitle: String {
        guard calendarService.hasAccess else {
            return "No Access"
        }

        guard let next = calendarService.nextMeeting else {
            return "No Meetings"
        }

        return next.menuBarTitle
    }

    private func startRefreshTimer() {
        refreshTimer?.invalidate()
        calendarService.fetchUpcomingMeetings()

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                calendarService.fetchUpcomingMeetings()
            }
        }
    }
}
