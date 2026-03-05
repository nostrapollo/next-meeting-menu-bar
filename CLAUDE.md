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

Test files exist at `NextMeeting/NextMeetingTests/` but the test target is **not registered** in the `.xcodeproj`. Tests cannot be run until a Unit Testing Bundle target is added. If/when added:

```bash
xcodebuild test -project NextMeeting/NextMeeting.xcodeproj -scheme NextMeeting -destination 'platform=macOS'
```

## Architecture

**Entry point:** `NextMeetingApp.swift` — SwiftUI `@main` App using `MenuBarExtra` with `.window` style. Creates all four services as `@StateObject` and passes them down via `@ObservedObject`.

**Services (all `@MainActor ObservableObject`):**

- **`CalendarService`** — EventKit integration. Fetches events, extracts meeting URLs via 11 regex patterns (Zoom, Google Meet, Teams, WebEx, Whereby, Around, Discord, Slack Huddle, Jitsi). Has a post-init circular dependency on PreferencesService resolved via `setPreferencesService(_:)`.
- **`PreferencesService`** — UserDefaults-backed settings: lookahead hours, refresh interval, alert timing, excluded calendars. Each `@Published` property persists on `didSet`.
- **`KeyboardShortcutService`** — Carbon framework global hotkey registration (`RegisterEventHotKey`). Requires Accessibility permission.
- **`LaunchAtLoginService`** — `SMAppService.mainApp` wrapper.

**Views:**

- **`MenuContentView`** — Main dropdown: meeting list (max 5), calendar access request, toggles, settings/quit buttons.
- **`SettingsView`** — Preferences pickers + calendar exclusion picker. Hosted in `SettingsWindowController` (singleton NSWindow).
- **`MeetingAlertWindow`** — Full-screen overlay alert at `NSWindow.level = .screenSaver`. Managed by `MeetingAlertWindowController` (plain class, not ObservableObject).

**Model:** `Meeting` struct with computed properties for countdown formatting (`countdownString`, `menuBarTitle`, `isHappeningNow`, `isJustStarting`).

## Key Patterns

- All persistence is UserDefaults — no Core Data or file storage.
- Pure Apple frameworks only: SwiftUI, EventKit, UserNotifications, ServiceManagement, Carbon, AppKit.
- Services are instantiated at the app level and injected downward; no EnvironmentObject usage.
- Deployment target: macOS 14.0. Bundle ID: `com.nextmeeting.app`.

## Git Conventions

- Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`
- Branch prefixes: `feat/`, `fix/`, `docs/`, `refactor/`
