import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferencesService: PreferencesService
    @ObservedObject var keyboardShortcutService: KeyboardShortcutService
    @ObservedObject var calendarService: CalendarService
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                // Lookahead Hours
                HStack {
                    Text("Lookahead Window:")
                        .frame(width: 140, alignment: .leading)

                    Picker("", selection: $preferencesService.lookaheadHours) {
                        Text("12 hours").tag(12)
                        Text("24 hours").tag(24)
                        Text("48 hours").tag(48)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }

                Text("How far ahead to show meetings")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 140)

                // Refresh Interval
                HStack {
                    Text("Refresh Interval:")
                        .frame(width: 140, alignment: .leading)

                    Picker("", selection: $preferencesService.refreshIntervalSeconds) {
                        Text("30 seconds").tag(30)
                        Text("1 minute").tag(60)
                        Text("5 minutes").tag(300)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }

                Text("How often to check for meeting updates")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 140)

                // Alert Timing
                HStack {
                    Text("Alert Timing:")
                        .frame(width: 140, alignment: .leading)

                    Picker("", selection: $preferencesService.alertMinutesBefore) {
                        Text("At start").tag(0)
                        Text("1 minute before").tag(1)
                        Text("5 minutes before").tag(5)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }

                Text("When to show full screen alerts")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 140)

                // Keyboard Shortcut
                HStack {
                    Text("Keyboard Shortcut:")
                        .frame(width: 140, alignment: .leading)

                    Toggle("", isOn: $keyboardShortcutService.isEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.small)

                    if keyboardShortcutService.isEnabled {
                        Text(keyboardShortcutService.shortcutDisplayString)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                Text("Press \(keyboardShortcutService.shortcutDisplayString) to join next meeting")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 140)
            }

            Divider()

            // Calendar Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Calendars")
                    .font(.headline)

                Text("Uncheck calendars to hide their meetings")
                    .font(.caption)
                    .foregroundColor(.secondary)

                let grouped = Dictionary(grouping: calendarService.availableCalendars) { $0.source }

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(grouped.keys.sorted(), id: \.self) { source in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(source)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.semibold)

                                ForEach(grouped[source] ?? []) { cal in
                                    CalendarToggleRow(
                                        calendar: cal,
                                        isEnabled: !preferencesService.excludedCalendarIDs.contains(cal.id),
                                        onToggle: { enabled in
                                            if enabled {
                                                preferencesService.excludedCalendarIDs.remove(cal.id)
                                            } else {
                                                preferencesService.excludedCalendarIDs.insert(cal.id)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 200)
            }

            Divider()

            HStack {
                Spacer()
                Button("Done") {
                    onDismiss?()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 400)
        .onAppear {
            calendarService.loadAvailableCalendars()
        }
    }
}

struct CalendarToggleRow: View {
    let calendar: CalendarInfo
    let isEnabled: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { onToggle($0) }
            ))
            .toggleStyle(.checkbox)
            .controlSize(.small)

            Circle()
                .fill(calendar.color)
                .frame(width: 8, height: 8)

            Text(calendar.title)
                .font(.system(size: 13))

            Spacer()
        }
        .padding(.leading, 8)
    }
}
