# NextMeeting

A simple macOS menu bar app that shows your next calendar meeting and a countdown timer.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Menu bar display** - Shows countdown + meeting title (e.g., "15m: Team Standup")
- **Quick overview** - Click to see your next 5 upcoming meetings
- **Join meetings** - One-click join for Zoom, Google Meet, Microsoft Teams, and WebEx
- **Auto-refresh** - Updates every 60 seconds
- **All calendars** - Works with any calendar configured in macOS Calendar app (iCloud, Google, Exchange, etc.)

## Screenshot

The menu bar shows your next meeting with a countdown:
```
📅 15m: Team Standup
```

Click to see the dropdown with upcoming meetings, times, and join buttons.

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15+ (for building)

## Installation

### Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/next-meeting-menu-bar.git
   cd next-meeting-menu-bar
   ```

2. Open in Xcode:
   ```bash
   open NextMeeting/NextMeeting.xcodeproj
   ```

3. Build and run (Cmd+R)

4. Grant calendar access when prompted

### First Run

On first launch, you'll be asked to grant calendar access. The app needs this to read your upcoming meetings. You can manage this permission in System Settings > Privacy & Security > Calendars.

## How It Works

The app uses Apple's EventKit framework to access your calendars. It:

1. Fetches events for the next 24 hours from all your calendars
2. Filters out all-day events
3. Extracts meeting URLs from event descriptions/locations (Zoom, Meet, Teams, WebEx)
4. Displays the next meeting with a countdown in your menu bar
5. Refreshes automatically every minute

## Project Structure

```
NextMeeting/
├── NextMeetingApp.swift          # App entry point with MenuBarExtra
├── Models/
│   └── Meeting.swift             # Meeting data model
├── Services/
│   └── CalendarService.swift     # EventKit integration
├── Views/
│   └── MenuContentView.swift     # Dropdown menu UI
└── Info.plist                    # Calendar permissions
```

## Disclaimer

This software is provided "as is" without warranty of any kind. Use at your own risk.

- This app accesses your calendar data locally on your device
- No data is sent to external servers
- The app requires calendar permissions to function
- Meeting join links are extracted using pattern matching and may not work for all meeting formats

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
