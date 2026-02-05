import EventKit
import SwiftUI

struct CalendarInfo: Identifiable, Hashable {
    let id: String
    let title: String
    let color: Color
    let source: String
}

@MainActor
class CalendarService: ObservableObject {
    private let eventStore = EKEventStore()
    private var alertedMeetingIds: Set<String> = []
    private var preferencesService: PreferencesService?

    @Published var meetings: [Meeting] = []
    @Published var hasAccess: Bool = false
    @Published var errorMessage: String?
    @Published var availableCalendars: [CalendarInfo] = []
    @Published var fullScreenAlertsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(fullScreenAlertsEnabled, forKey: "fullScreenAlertsEnabled")
        }
    }
    
    func setPreferencesService(_ service: PreferencesService) {
        self.preferencesService = service
    }

    var meetingToAlert: Meeting? {
        guard fullScreenAlertsEnabled else { return nil }
        
        let alertMinutes = preferencesService?.alertMinutesBefore ?? 0
        
        guard let meeting = meetings.first(where: { meeting in
            if alertedMeetingIds.contains(meeting.id) {
                return false
            }
            
            let now = Date()
            let secondsUntilStart = meeting.startDate.timeIntervalSince(now)
            let minutesUntilStart = secondsUntilStart / 60
            
            // Alert if we're within the specified minutes before start
            if alertMinutes == 0 {
                // At start: within 0 to 60 seconds after start
                return meeting.isJustStarting
            } else {
                // Before start: check if we're within the alert window (e.g., 1-2 minutes before for 1 minute setting)
                return minutesUntilStart >= Double(alertMinutes - 1) && minutesUntilStart <= Double(alertMinutes)
            }
        }) else {
            return nil
        }
        return meeting
    }

    func markMeetingAlerted(_ meeting: Meeting) {
        alertedMeetingIds.insert(meeting.id)
    }
    
    private func cleanupAlertedMeetingIds() {
        let currentMeetingIds = Set(meetings.map { $0.id })
        alertedMeetingIds = alertedMeetingIds.intersection(currentMeetingIds)
    }

    var currentMeeting: Meeting? {
        meetings.first { $0.isHappeningNow }
    }

    var nextMeeting: Meeting? {
        meetings.first { !$0.isHappeningNow }
    }

    init() {
        self.fullScreenAlertsEnabled = UserDefaults.standard.bool(forKey: "fullScreenAlertsEnabled")
        checkAuthorizationStatus()
    }

    func checkAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(macOS 14.0, *) {
            hasAccess = status == .fullAccess
        } else {
            hasAccess = status == .authorized
        }
    }

    func requestAccess() async {
        if #available(macOS 14.0, *) {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                hasAccess = granted
                if granted {
                    fetchUpcomingMeetings()
                }
            } catch {
                print("Failed to request calendar access: \(error)")
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                Task { @MainActor in
                    self?.hasAccess = granted
                    if granted {
                        self?.fetchUpcomingMeetings()
                    }
                }
            }
        }
    }

    func loadAvailableCalendars() {
        guard hasAccess else { return }
        let ekCalendars = eventStore.calendars(for: .event)
        availableCalendars = ekCalendars.map { cal in
            CalendarInfo(
                id: cal.calendarIdentifier,
                title: cal.title,
                color: Color(cgColor: cal.cgColor),
                source: cal.source.title
            )
        }.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func fetchUpcomingMeetings() {
        guard hasAccess else { return }

        do {
            let now = Date()
            let lookaheadHours = preferencesService?.lookaheadHours ?? 24
            let endDate = Calendar.current.date(byAdding: .hour, value: lookaheadHours, to: now)!

            let excludedIDs = preferencesService?.excludedCalendarIDs ?? []
            let calendars: [EKCalendar]? = excludedIDs.isEmpty ? nil : eventStore.calendars(for: .event).filter { !excludedIDs.contains($0.calendarIdentifier) }

            let predicate = eventStore.predicateForEvents(
                withStart: now,
                end: endDate,
                calendars: calendars
            )

            let events = eventStore.events(matching: predicate)
                .filter { !$0.isAllDay }
                .sorted { $0.startDate < $1.startDate }

            meetings = events.map { event in
                Meeting(
                    id: event.eventIdentifier,
                    title: event.title ?? "Untitled",
                    startDate: event.startDate,
                    endDate: event.endDate,
                    calendarColor: Color(cgColor: event.calendar.cgColor),
                    calendarName: event.calendar.title,
                    meetingURL: extractMeetingURL(from: event)
                )
            }
            
            cleanupAlertedMeetingIds()
            
            // Clear error message on success
            errorMessage = nil
        } catch {
            errorMessage = "Failed to fetch meetings: \(error.localizedDescription)"
        }
    }

    private func extractMeetingURL(from event: EKEvent) -> URL? {
        let patterns = [
            #"https?://[\w.-]*zoom\.us/j/[\d\w?=&]+"#,
            #"https?://meet\.google\.com/[\w-]+"#,
            #"https?://teams\.microsoft\.com/l/meetup-join/[\w%/-]+"#,
            #"https?://[\w.-]+\.webex\.com/[\w/.-]+"#,
            #"https?://whereby\.com/[\w-]+"#,
            #"https?://around\.co/[\w-]+"#,
            #"https?://discord\.gg/[\w-]+"#,
            #"https?://discord\.com/channels/[\d/]+"#,
            #"https?://app\.slack\.com/huddle/[\w/-]+"#,
            #"https?://meet\.jit\.si/[\w-]+"#,
            #"https?://[\w.-]+\.zoom\.us/j/[\d\w?=&]+"#
        ]

        let textsToSearch = [
            event.url?.absoluteString,
            event.location,
            event.notes
        ].compactMap { $0 }

        for text in textsToSearch {
            for pattern in patterns {
                if let url = findURL(matching: pattern, in: text) {
                    return url
                }
            }
        }

        if let eventURL = event.url {
            return eventURL
        }

        return nil
    }

    private func findURL(matching pattern: String, in text: String) -> URL? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        if let match = regex.firstMatch(in: text, options: [], range: range) {
            if let matchRange = Range(match.range, in: text) {
                let urlString = String(text[matchRange])
                return URL(string: urlString)
            }
        }

        return nil
    }
}
