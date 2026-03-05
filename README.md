# NextMeeting

A macOS menu bar app that shows a live countdown to your next meeting. Press **Cmd+Shift+J** from anywhere to join instantly. No clicking through calendar apps, no hunting for links.

NextMeeting reads your local calendars, extracts meeting URLs from event titles, notes, locations, and URL fields, and supports Zoom, Google Meet, Microsoft Teams, WebEx, Whereby, Around, Discord, Slack Huddles, and Jitsi.

## Quick Start

```sh
git clone https://github.com/nostrapollo/next-meeting-menu-bar.git
cd next-meeting-menu-bar
./build.sh          # Release build
./build.sh Debug    # Debug build

# Or open in Xcode
open NextMeeting/NextMeeting.xcodeproj
# Build and run with Cmd+R
```

On first launch, grant **Calendar access** when prompted. For the global keyboard shortcut, enable **Accessibility** access in System Settings > Privacy & Security > Accessibility.

## Features

| Feature | Details |
|---------|---------|
| Menu bar countdown | Live display: `15m: Team Standup` |
| Global shortcut | **Cmd+Shift+J** joins current/next meeting from any app |
| Full-screen alerts | Optional popup at start, 1min, or 5min before |
| Calendar picker | Choose which calendars to show |
| Launch at Login | Native macOS integration via SMAppService |
| Lookahead | 12h, 24h, or 48h |
| Refresh interval | 30s, 60s, or 5min |

## Supported Platforms

Zoom (including vanity URLs), Google Meet, Microsoft Teams, WebEx, Whereby, Around, Discord, Slack Huddles, Jitsi.

Meeting URLs are extracted from event URL, location, and notes fields using pattern matching.

## Requirements

- macOS 13.0 (Ventura) or later
- Calendar access (reads events locally — no data leaves your Mac)
- Accessibility access (for global keyboard shortcut)

## Privacy

Everything runs locally. No analytics, no telemetry, no network requests except opening meeting URLs when you click Join. No third-party dependencies — pure Apple frameworks only.

## Troubleshooting

**Keyboard shortcut not working?**
Check System Settings > Privacy & Security > Accessibility. Make sure NextMeeting is listed and enabled. Try toggling it off and on.

**Meetings not showing?**
Check System Settings > Privacy & Security > Calendars. Verify the calendar is enabled in Calendar.app.

**Meeting URL not detected?**
NextMeeting looks for URLs in event titles, notes, location, and URL fields. If your meeting link isn't being found, [open an issue](https://github.com/nostrapollo/next-meeting-menu-bar/issues) with the meeting platform.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

```sh
git checkout -b feat/your-feature
# make changes
git commit -m 'feat: add your feature'
git push origin feat/your-feature
# open a PR
```

## License

MIT — see [LICENSE](LICENSE).
