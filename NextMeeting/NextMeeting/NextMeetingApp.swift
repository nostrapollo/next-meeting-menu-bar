import AppKit
import SwiftUI
import UserNotifications
import os

@main
struct NextMeetingApp: App {
    private static let logger = Logger(subsystem: "com.nextmeeting.app", category: "App")

    @StateObject private var preferencesService: PreferencesService
    @StateObject private var calendarService: CalendarService
    @StateObject private var launchAtLoginService: LaunchAtLoginService
    @StateObject private var keyboardShortcutService: KeyboardShortcutService
    private let alertController = MeetingAlertWindowController()

    // Setup happens here rather than in the menu content's .onAppear: with the
    // .window MenuBarExtra style the content view isn't created until the menu
    // is first opened, so onAppear-based setup would leave the app without a
    // fetch, refresh timer, or hotkey after a launch-at-login start.
    init() {
        let preferences = PreferencesService()
        let calendar = CalendarService(preferencesService: preferences)
        let launchAtLogin = LaunchAtLoginService()
        let shortcut = KeyboardShortcutService()

        _preferencesService = StateObject(wrappedValue: preferences)
        _calendarService = StateObject(wrappedValue: calendar)
        _launchAtLoginService = StateObject(wrappedValue: launchAtLogin)
        _keyboardShortcutService = StateObject(wrappedValue: shortcut)

        shortcut.setup { [weak calendar] in
            guard let calendar else { return }
            Self.joinNextMeeting(from: calendar)
        }

        Self.requestNotificationPermissions()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(
                calendarService: calendarService,
                launchAtLoginService: launchAtLoginService,
                preferencesService: preferencesService,
                keyboardShortcutService: keyboardShortcutService
            )
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                Text(menuBarTitle)
            }
        }
        .menuBarExtraStyle(.window)
        .onChange(of: preferencesService.refreshIntervalSeconds) { _, _ in
            calendarService.restartRefreshTimer()
        }
        .onChange(of: preferencesService.excludedCalendarIDs) { _, _ in
            if calendarService.hasAccess {
                calendarService.fetchUpcomingMeetings()
            }
        }
        .onChange(of: calendarService.meetingToAlert?.id) { _, _ in
            if let meeting = calendarService.meetingToAlert {
                showAlert(for: meeting)
            }
        }
    }

    private var menuBarTitle: String {
        guard calendarService.hasAccess else {
            return "No Access"
        }

        // Fall back to the in-progress meeting so the title doesn't claim
        // "No Meetings" while your last meeting of the day is happening.
        guard let meeting = calendarService.nextMeeting ?? calendarService.currentMeeting else {
            return "No Meetings"
        }

        return meeting.menuBarTitle(at: calendarService.now)
    }

    private func showAlert(for meeting: Meeting) {
        calendarService.markMeetingAlerted(meeting)
        alertController.showAlert(for: meeting) { url in
            NSWorkspace.shared.open(url)
        }
    }

    @MainActor
    private static func joinNextMeeting(from calendarService: CalendarService) {
        let meetingToJoin = calendarService.currentMeeting ?? calendarService.nextMeeting

        guard let meeting = meetingToJoin else {
            notify(title: "No Meeting to Join", body: "There are no upcoming meetings at this time.")
            return
        }

        guard let url = meeting.meetingURL else {
            notify(title: "No Meeting URL", body: "'\(meeting.title)' doesn't have a meeting URL.")
            return
        }

        NSWorkspace.shared.open(url)
        notify(title: "Joining Meeting", body: meeting.title)
    }

    private static func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error {
                logger.error("Notification permission error: \(error)")
            }
        }
    }

    private static func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                logger.error("Failed to show notification: \(error)")
            }
        }
    }
}
