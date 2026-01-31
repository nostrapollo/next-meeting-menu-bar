import SwiftUI

struct MenuContentView: View {
    @ObservedObject var calendarService: CalendarService
    @ObservedObject var launchAtLoginService: LaunchAtLoginService
    @ObservedObject var preferencesService: PreferencesService
    @Environment(\.openURL) private var openURL
    @State private var showingSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if calendarService.hasAccess {
                meetingsContent
            } else {
                requestAccessView
            }

            Divider()
                .padding(.vertical, 8)

            footerButtons
        }
        .padding(.vertical, 8)
        .frame(width: 300)
        .sheet(isPresented: $showingSettings) {
            SettingsView(preferencesService: preferencesService)
        }
    }

    @ViewBuilder
    private var meetingsContent: some View {
        if let errorMessage = calendarService.errorMessage {
            VStack(spacing: 12) {
                Text("Error Loading Meetings")
                    .font(.headline)
                    .foregroundColor(.red)
                
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                Button("Retry") {
                    calendarService.fetchUpcomingMeetings()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity)
        } else if calendarService.meetings.isEmpty {
            Text("No upcoming meetings")
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        } else {
            Text("Upcoming Meetings")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.bottom, 4)

            ForEach(calendarService.meetings.prefix(5)) { meeting in
                MeetingRowView(meeting: meeting, openURL: openURL)
            }
        }
    }

    private var requestAccessView: some View {
        VStack(spacing: 12) {
            Text("Calendar Access Required")
                .font(.headline)

            Text("Grant access to see your upcoming meetings")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Grant Access") {
                Task {
                    await calendarService.requestAccess()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    private var footerButtons: some View {
        VStack(spacing: 4) {
            Toggle(isOn: $calendarService.fullScreenAlertsEnabled) {
                HStack {
                    Image(systemName: "bell.badge")
                    Text("Full Screen Alerts")
                    Spacer()
                }
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            Toggle(isOn: $launchAtLoginService.isEnabled) {
                HStack {
                    Image(systemName: "power")
                    Text("Launch at Login")
                    Spacer()
                }
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            Divider()
                .padding(.vertical, 4)

            Button {
                calendarService.fetchUpcomingMeetings()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            Button {
                showingSettings = true
            } label: {
                HStack {
                    Image(systemName: "gear")
                    Text("Settings")
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            Divider()
                .padding(.vertical, 4)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "power")
                    Text("Quit")
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
    }
}

struct MeetingRowView: View {
    let meeting: Meeting
    let openURL: OpenURLAction

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(meeting.calendarColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(meeting.title)
                    .lineLimit(1)
                    .font(.system(size: 13))

                HStack(spacing: 4) {
                    Text(meeting.timeString)
                    Text("•")
                    Text(meeting.countdownString)
                        .foregroundColor(meeting.isHappeningNow ? .green : .secondary)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            if let url = meeting.meetingURL {
                Button {
                    openURL(url)
                } label: {
                    Text("Join")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
