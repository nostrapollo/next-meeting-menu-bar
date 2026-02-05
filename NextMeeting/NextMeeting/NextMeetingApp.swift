import SwiftUI
import UserNotifications

@main
struct NextMeetingApp: App {
    @StateObject private var preferencesService = PreferencesService()
    @StateObject private var calendarService = CalendarService()
    @StateObject private var launchAtLoginService = LaunchAtLoginService()
    @StateObject private var keyboardShortcutService = KeyboardShortcutService()
    @State private var refreshTimer: Timer?
    @State private var hasInitialized = false
    private let alertController = MeetingAlertWindowController()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(
                calendarService: calendarService,
                launchAtLoginService: launchAtLoginService,
                preferencesService: preferencesService,
                keyboardShortcutService: keyboardShortcutService
            )
            .onAppear {
                guard !hasInitialized else { return }
                hasInitialized = true
                calendarService.setPreferencesService(preferencesService)
                setupKeyboardShortcut()
                requestNotificationPermissions()
                if calendarService.hasAccess {
                    startRefreshTimer()
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                Text(menuBarTitle)
            }
        }
        .menuBarExtraStyle(.window)
        .onChange(of: calendarService.hasAccess) { _, newValue in
            if newValue {
                calendarService.setPreferencesService(preferencesService)
                startRefreshTimer()
            }
        }
        .onChange(of: preferencesService.refreshIntervalSeconds) { _, _ in
            if calendarService.hasAccess {
                startRefreshTimer()
            }
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
    
    private func setupKeyboardShortcut() {
        keyboardShortcutService.setup { [self] in
            handleKeyboardShortcut()
        }
    }
    
    private func handleKeyboardShortcut() {
        // Try current meeting first, then next meeting
        let meetingToJoin = calendarService.currentMeeting ?? calendarService.nextMeeting
        
        guard let meeting = meetingToJoin else {
            showNoMeetingNotification()
            return
        }
        
        guard let url = meeting.meetingURL else {
            showNoMeetingURLNotification(meetingTitle: meeting.title)
            return
        }
        
        NSWorkspace.shared.open(url)
        showMeetingJoinedNotification(meetingTitle: meeting.title)
    }
    
    private func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    private func showNoMeetingNotification() {
        let content = UNMutableNotificationContent()
        content.title = "No Meeting to Join"
        content.body = "There are no upcoming meetings at this time."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                           content: content,
                                           trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to show notification: \(error)")
            }
        }
    }
    
    private func showNoMeetingURLNotification(meetingTitle: String) {
        let content = UNMutableNotificationContent()
        content.title = "No Meeting URL"
        content.body = "'\(meetingTitle)' doesn't have a meeting URL."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                           content: content,
                                           trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to show notification: \(error)")
            }
        }
    }
    
    private func showMeetingJoinedNotification(meetingTitle: String) {
        let content = UNMutableNotificationContent()
        content.title = "Joining Meeting"
        content.body = meetingTitle
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                           content: content,
                                           trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to show notification: \(error)")
            }
        }
    }
}
