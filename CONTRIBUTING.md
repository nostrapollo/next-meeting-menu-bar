# Contributing to NextMeeting

Thanks for your interest in contributing! This document outlines the process for contributing to NextMeeting.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/next-meeting-menu-bar.git`
3. Open in Xcode: `open NextMeeting/NextMeeting.xcodeproj`
4. Create a branch: `git checkout -b feat/your-feature`

## Development Setup

### Requirements
- macOS 13.0+
- Xcode 15+
- Swift 5.9+

### Building
```bash
# Open project
open NextMeeting/NextMeeting.xcodeproj

# Build (in Xcode)
⌘B

# Run
⌘R
```

### Code Style

We use SwiftLint for code quality. Install it via Homebrew:
```bash
brew install swiftlint
```

Run before committing:
```bash
swiftlint lint NextMeeting/
```

## Making Changes

### Branch Naming
- `feat/description` — New features
- `fix/description` — Bug fixes
- `docs/description` — Documentation
- `refactor/description` — Code refactoring

### Commit Messages
Follow [Conventional Commits](https://www.conventionalcommits.org/):
```
feat: add support for Slack huddles
fix: prevent memory leak in alert service
docs: update installation instructions
```

### Pull Requests

1. Update documentation if needed
2. Add tests for new functionality
3. Ensure SwiftLint passes
4. Reference any related issues
5. Provide a clear description of changes

## Architecture

### Services
- `CalendarService` — EventKit integration, meeting fetching
- `PreferencesService` — UserDefaults-backed settings
- `KeyboardShortcutService` — Global hotkey handling
- `LaunchAtLoginService` — SMAppService integration

### Views
- `MenuContentView` — Main dropdown menu
- `SettingsView` — Preferences panel
- `MeetingAlertWindow` — Full-screen alerts

### Models
- `Meeting` — Core meeting data model with computed properties

## App Icon

The icon is generated, not hand-drawn — run from the repository root:

```bash
swift scripts/generate-app-icon.swift
```

It renders the same `calendar` SF Symbol the menu bar uses, so the two can't
drift apart, and writes all ten slots into `AppIcon.appiconset` plus its
`Contents.json`. Each size is rendered natively from the vector symbol rather
than downscaled from one master, so the 16pt slot stays crisp.

Tile geometry and colours are constants at the top of the script. It refuses to
run if the glyph-to-tile contrast falls below 3:1, so the icon stays legible by
brightness rather than relying on hue.

## Adding Meeting Platform Support

To add a new meeting platform:

1. Open `CalendarService.swift`
2. Find the `extractMeetingURL` function
3. Add a regex pattern to the `patterns` array:
```swift
#"https?://your-platform\.com/[\w/-]+"#
```
4. Add a test in `URLExtractionTests.swift`
5. Update the README

## Testing

Test files are in `NextMeeting/NextMeetingTests/`:
- `MeetingTests.swift` — Meeting model tests
- `URLExtractionTests.swift` — URL pattern tests

To add tests to the Xcode project:
1. File → New → Target → Unit Testing Bundle
2. Add test files to the target

## Questions?

Open an issue or reach out to the maintainers.

Thank you for contributing! 🎉
