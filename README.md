# NextMeeting

**Your next meeting, always visible. Join with one click — or one keystroke.**

[![macOS 13+](https://img.shields.io/badge/macOS-13.0%2B-blue?logo=apple)](https://www.apple.com/macos/)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white)](https://swift.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)


<!-- TODO: Add hero image/GIF showing menu bar + dropdown -->
<!-- <p align="center">
  <img src="assets/hero.png" alt="NextMeeting screenshot" width="600">
</p> -->

## Why NextMeeting?

You're in the zone. Deep in code, writing, whatever. Then you glance at the clock — *wait, did I miss that meeting?*

NextMeeting sits quietly in your menu bar, showing exactly when your next meeting starts and what it is. When it's time, press **⌘⇧J** from anywhere to join instantly. No clicking through calendar apps. No hunting for links.

## Download

### Homebrew (recommended)
```bash
brew install --cask next-meeting
```
*Coming soon — star the repo to get notified!*

### Direct Download
[**Download Latest Release →**](https://github.com/nostrapollo/next-meeting-menu-bar/releases/latest)

### Build from Source
```bash
git clone https://github.com/nostrapollo/next-meeting-menu-bar.git
cd next-meeting-menu-bar
open NextMeeting/NextMeeting.xcodeproj
# Build and run with ⌘R
```

## Features

### 🎯 Always Know What's Next
Your menu bar shows a live countdown: `15m: Team Standup`. Click to see your next 5 meetings with calendar colors and join buttons.

### ⌨️ Global Keyboard Shortcut
Press **⌘⇧J** from any app to instantly join your current or next meeting. No window switching required.

### 🔔 Full-Screen Alerts
Optional popup notifications when meetings start — configurable for at-start, 1 minute, or 5 minutes before.

### 🔗 Works With Everything
- Zoom (including custom vanity URLs)
- Google Meet
- Microsoft Teams
- WebEx
- Whereby
- Around
- Discord
- Slack Huddles
- Jitsi

### ⚙️ Customizable
| Setting | Options |
|---------|---------|
| Lookahead | 12h, 24h, 48h |
| Refresh | 30s, 60s, 5min |
| Alerts | Off, at start, 1min before, 5min before |
| Launch at Login | On/Off |

## Requirements

- macOS 13.0 (Ventura) or later
- Calendar access (to read your events)
- Accessibility access (for global keyboard shortcut)

## First Launch

1. **Grant calendar access** when prompted
2. **Enable accessibility** for the keyboard shortcut:  
   System Settings → Privacy & Security → Accessibility → Enable NextMeeting
3. Optionally enable **Launch at Login** from the app menu

## How It Compares

| Feature | NextMeeting | MeetingBar | Meeter |
|---------|:-----------:|:----------:|:------:|
| Menu bar countdown | ✅ | ✅ | ✅ |
| Global keyboard shortcut | ✅ **⌘⇧J** | ❌ | ❌ |
| Full-screen alerts | ✅ | ❌ | ✅ |
| Free & open source | ✅ | ✅ | ❌ |
| Native SwiftUI | ✅ | ❌ | ❌ |
| Lightweight (~5MB) | ✅ | ❌ | ❌ |

## Privacy

- ✅ **100% local** — your calendar data never leaves your Mac
- ✅ **No analytics** — no tracking, no telemetry
- ✅ **No network requests** — except opening meeting URLs
- ✅ **Open source** — audit every line of code

## Troubleshooting

### Keyboard shortcut not working?
1. Check System Settings → Privacy & Security → Accessibility
2. Make sure NextMeeting is listed and enabled
3. Try toggling it off and on again
4. If still not working, remove and re-add the app

### Meetings not showing?
1. Check System Settings → Privacy & Security → Calendars
2. Make sure NextMeeting has access to your calendars
3. Verify the calendar is enabled in Calendar.app

### Meeting URL not detected?
NextMeeting looks for URLs in event titles, notes, location, and URL fields. If your meeting link isn't being found, [open an issue](https://github.com/nostrapollo/next-meeting-menu-bar/issues) with the meeting platform and we'll add support.

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

**Quick start:**
```bash
git checkout -b feat/your-feature
# make changes
git commit -m 'feat: add your feature'
git push origin feat/your-feature
# open a PR
```

## Support

- 🐛 [Report a bug](https://github.com/nostrapollo/next-meeting-menu-bar/issues/new?template=bug_report.md)
- 💡 [Request a feature](https://github.com/nostrapollo/next-meeting-menu-bar/issues/new?template=feature_request.md)
- ⭐ [Star this repo](https://github.com/nostrapollo/next-meeting-menu-bar/stargazers) if you find it useful!

## License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  <sub>Built with ❤️ in Swift. If NextMeeting saves you time, consider starring the repo!</sub>
</p>
