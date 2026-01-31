# NextMeeting

A simple, powerful macOS menu bar app that shows your next calendar meeting with a countdown timer.

[![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/nostrapollo/next-meeting-menu-bar?include_prereleases)](https://github.com/nostrapollo/next-meeting-menu-bar/releases)

## Features

### Core
- **Menu bar countdown** — Shows time until next meeting (e.g., "15m: Team Standup")
- **Quick overview** — Click to see your next 5 upcoming meetings
- **One-click join** — Join buttons for all major platforms
- **Full-screen alerts** — Optional popup when meetings start
- **Launch at login** — Start automatically with your Mac

### Meeting Platforms Supported
- Zoom (including custom vanity URLs)
- Google Meet
- Microsoft Teams
- WebEx
- Whereby
- Around
- Discord
- Slack Huddles
- Jitsi

### Keyboard Shortcut
Press **⌘⇧J** (Command+Shift+J) from anywhere to instantly join your next meeting.

### Customizable Settings
| Setting | Options |
|---------|---------|
| Lookahead Window | 12h, 24h, 48h |
| Refresh Interval | 30s, 60s, 5min |
| Alert Timing | At start, 1min before, 5min before |
| Keyboard Shortcut | Enable/disable |

## Screenshot

```
📅 15m: Team Standup
```

Click the menu bar icon to see:
- Upcoming meetings with join buttons
- Calendar color indicators
- Settings access

## Installation

### Homebrew (coming soon)
```bash
brew install --cask next-meeting
```

### Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/nostrapollo/next-meeting-menu-bar.git
   cd next-meeting-menu-bar
   ```

2. Open in Xcode:
   ```bash
   open NextMeeting/NextMeeting.xcodeproj
   ```

3. Build and run (⌘R)

4. Grant calendar access when prompted

## Requirements

- macOS 13.0 (Ventura) or later
- Calendar access permission
- Accessibility permission (for global keyboard shortcut)

## First Run

On first launch:
1. Grant **calendar access** when prompted
2. Grant **accessibility access** for the keyboard shortcut (System Settings → Privacy & Security → Accessibility)
3. Optionally enable "Launch at Login" in the app menu

## How It Works

NextMeeting uses Apple's EventKit framework to:

1. Fetch events from all your calendars
2. Filter out all-day events
3. Extract meeting URLs using pattern matching
4. Display countdown in your menu bar
5. Refresh automatically based on your settings

All data stays on your device — nothing is sent to external servers.

## Project Structure

```
NextMeeting/
├── NextMeetingApp.swift              # App entry point
├── Models/
│   └── Meeting.swift                 # Meeting data model
├── Services/
│   ├── CalendarService.swift         # EventKit integration
│   ├── PreferencesService.swift      # User settings
│   ├── KeyboardShortcutService.swift # Global hotkey
│   └── LaunchAtLoginService.swift    # Auto-start
└── Views/
    ├── MenuContentView.swift         # Dropdown menu
    ├── SettingsView.swift            # Preferences panel
    └── MeetingAlertWindow.swift      # Full-screen alerts
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feat/amazing-feature`)
5. Open a Pull Request

See [open issues](https://github.com/nostrapollo/next-meeting-menu-bar/issues) for ideas.

## Privacy

- ✅ All data stays on your device
- ✅ No analytics or tracking
- ✅ No network requests (except opening meeting URLs)
- ✅ Open source — audit the code yourself

## License

MIT License — see [LICENSE](LICENSE) for details.

## Acknowledgments

Built with ❤️ using SwiftUI and EventKit.
