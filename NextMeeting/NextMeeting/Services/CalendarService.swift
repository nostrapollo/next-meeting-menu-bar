import EventKit
import SwiftUI

@MainActor
class CalendarService: ObservableObject {
    private let eventStore = EKEventStore()
    private var alertedMeetingIds: Set<String> = []

    @Published var meetings: [Meeting] = []
    @Published var hasAccess: Bool = false
    @Published var fullScreenAlertsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(fullScreenAlertsEnabled, forKey: "fullScreenAlertsEnabled")
        }
    }

    var meetingToAlert: Meeting? {
        guard fullScreenAlertsEnabled else { return nil }
        guard let meeting = meetings.first(where: { $0.isJustStarting && !alertedMeetingIds.contains($0.id) }) else {
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

    func fetchUpcomingMeetings() {
        guard hasAccess else { return }

        let now = Date()
        let endDate = Calendar.current.date(byAdding: .hour, value: 24, to: now)!

        let predicate = eventStore.predicateForEvents(
            withStart: now,
            end: endDate,
            calendars: nil
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
    }

    private func extractMeetingURL(from event: EKEvent) -> URL? {
        let patterns = [
            #"https?://[\w.-]*zoom\.us/j/[\d\w?=&]+"#,
            #"https?://meet\.google\.com/[\w-]+"#,
            #"https?://teams\.microsoft\.com/l/meetup-join/[\w%/-]+"#,
            #"https?://[\w.-]+\.webex\.com/[\w/.-]+"#
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
