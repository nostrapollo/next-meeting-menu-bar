# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NextMeeting is a macOS menu bar app (Swift/SwiftUI) that shows a live countdown to your next calendar event and provides a global keyboard shortcut (Cmd+Shift+J) to join meetings. It runs as an LSUIElement (no Dock icon), uses App Sandbox with calendar entitlement, and has zero third-party dependencies.

## Build & Run

```bash
# Build from command line
xcodebuild build -project NextMeeting/NextMeeting.xcodeproj -scheme NextMeeting -destination 'platform=macOS'

# Or open in Xcode and Cmd+R
open NextMeeting/NextMeeting.xcodeproj
```

Xcode project is at `NextMeeting/NextMeeting.xcodeproj`. No Package.swift, no CocoaPods, no SPM dependencies.

## Linting

```bash
swiftlint lint NextMeeting/
```

Config in `.swiftlint.yml`: `line_length` and `trailing_whitespace` are disabled. `force_unwrapping` is opted in. Function body limit is 50 lines (warning) / 100 (error).

## Testing

```bash
./test.sh
```

Tests run with the Command Line Tools alone — no Xcode or XCTest. `test.sh` compiles the pure-logic sources (`Meeting`, `MeetingURLExtractor`, `MeetingAlertPolicy`) together with `NextMeeting/NextMeetingTests/` (a small assertion harness, `TestHarness.swift`, plus `main.swift` runner) into a plain executable and runs it. Time-dependent tests inject a fixed `now` — never assert against the wall clock. Add new cases to the existing `run*Tests()` functions or register a new one in `main.swift`.

## Architecture

**Entry point:** `NextMeetingApp.swift` — SwiftUI `@main` App using `MenuBarExtra` with `.window` style. Creates and wires all four services in `App.init` (NOT in the content view's `.onAppear` — with the `.window` style the content view doesn't exist until the menu is first opened, so onAppear-based setup breaks launch-at-login starts).

**Services (all `@MainActor ObservableObject`):**

- **`CalendarService`** — EventKit integration; takes `PreferencesService` in its init. Owns two timers: a fetch timer on the configured refresh interval, and a 1-second display timer that publishes `now` (drives live countdown rendering) and evaluates `MeetingAlertPolicy` (so the one-minute alert window can't be skipped by a slow refresh interval). Meeting ids come from `Meeting.makeID` (eventIdentifier + start date — recurring occurrences must not share an id).
- **`MeetingURLExtractor`** — pure regex-based URL extraction (Zoom, Google Meet, Teams, WebEx, Whereby, Around, Discord, Slack Huddle, Jitsi), no EventKit dependency, unit tested directly. Patterns live ONLY here — never duplicate them in tests.
- **`MeetingAlertPolicy`** — pure alert-window selection with injectable clock, unit tested directly.
- **`PreferencesService`** — UserDefaults-backed settings: lookahead hours, refresh interval, alert timing, excluded calendars. Each `@Published` property persists on `didSet`.
- **`KeyboardShortcutService`** — Carbon framework global hotkey registration (`RegisterEventHotKey`). Requires Accessibility permission.
- **`LaunchAtLoginService`** — `SMAppService.mainApp` wrapper.

**Views:**

- **`MenuContentView`** — Main dropdown: meeting list (max 5), calendar access request, toggles, settings/quit buttons.
- **`SettingsView`** — Preferences pickers + calendar exclusion picker. Hosted in `SettingsWindowController` (singleton NSWindow).
- **`MeetingAlertWindow`** — Full-screen overlay alert at `NSWindow.level = .screenSaver`. Managed by `MeetingAlertWindowController` (plain class, not ObservableObject).

**Model:** `Meeting` struct with time-parameterized functions for countdown formatting (`countdownString(at:)`, `menuBarTitle(at:)`, `isHappeningNow(at:)`, `isJustStarting(at:)`) plus parameterless convenience properties for views.

## Key Patterns

- All persistence is UserDefaults — no Core Data or file storage.
- Pure Apple frameworks only: SwiftUI, EventKit, UserNotifications, ServiceManagement, Carbon, AppKit.
- Services are instantiated at the app level and injected downward; no EnvironmentObject usage.
- Deployment target: macOS 14.0. Bundle ID: `com.nextmeeting.app`.

## Git Conventions

- Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`
- Branch prefixes: `feat/`, `fix/`, `docs/`, `refactor/`
