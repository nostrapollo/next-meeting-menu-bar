#!/bin/bash
# Runs the unit tests with the Command Line Tools toolchain — no Xcode needed.
# The tests cover the pure logic (Meeting, MeetingURLExtractor,
# MeetingAlertPolicy) compiled together with a tiny assertion harness.
set -euo pipefail
cd "$(dirname "$0")"

BUILD_DIR="build"
mkdir -p "$BUILD_DIR"

swiftc \
  -sdk "$(xcrun --show-sdk-path)" \
  -o "$BUILD_DIR/nextmeeting-tests" \
  NextMeeting/NextMeeting/Models/Meeting.swift \
  NextMeeting/NextMeeting/Services/MeetingURLExtractor.swift \
  NextMeeting/NextMeeting/Services/MeetingAlertPolicy.swift \
  NextMeeting/NextMeetingTests/*.swift

"$BUILD_DIR/nextmeeting-tests"
