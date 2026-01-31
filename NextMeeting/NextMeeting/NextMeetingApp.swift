import SwiftUI

@main
struct NextMeetingApp: App {
    @StateObject private var preferencesService = PreferencesService()
    @StateObject private var calendarService = CalendarService()
    @StateObject private var launchAtLoginService = LaunchAtLoginService()
    @State private var refreshTimer: Timer?
    private let alertController = MeetingAlertWindowController()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(
                calendarService: calendarService,
                launchAtLoginService: launchAtLoginService,
                preferencesService: preferencesService
            )
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                Text(menuBarTitle)
            }
        }
        .menuBarExtraStyle(.window)
        .onChange(of: calendarService.hasAccess) { newValue in
            if newValue {
                calendarService.setPreferencesService(preferencesService)
                startRefreshTimer()
            }
        }
        .onChange(of: preferencesService.refreshIntervalSeconds) { _ in
            if calendarService.hasAccess {
                startRefreshTimer()
            }
        }
        .onChange(of: calendarService.meetingToAlert?.id) { meetingId in
            if let meeting = calendarService.meetingToAlert {
                showAlert(for: meeting)
            }
        }
        .onAppear {
            calendarService.setPreferencesService(preferencesService)
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

        let interval = TimeInterval(preferencesService.refreshIntervalSeconds)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { @MainActor in
                calendarService.fetchUpcomingMeetings()
            }
        }
    }

    private func showAlert(for meeting: Meeting) {
        calendarService.markMeetingAlerted(meeting)
        alertController.showAlert(for: meeting) { url in
            NSWorkspace.shared.open(url)
        }
    }
}
