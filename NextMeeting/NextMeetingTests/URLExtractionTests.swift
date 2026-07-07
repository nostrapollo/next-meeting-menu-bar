import Foundation

/// These exercise the real `MeetingURLExtractor` used by the app — not a copy
/// of its patterns — so a regex change that breaks extraction fails here.
func runURLExtractionTests() {
    print("MeetingURLExtractor")

    func extracted(_ text: String) -> String? {
        MeetingURLExtractor.extractURL(from: [text])?.absoluteString
    }

    // MARK: Zoom

    TestRunner.test("extracts Zoom URL with password") {
        TestRunner.expectEqual(
            extracted("Join us at https://zoom.us/j/123456789?pwd=abc123"),
            "https://zoom.us/j/123456789?pwd=abc123"
        )
    }

    TestRunner.test("extracts Zoom vanity URL") {
        TestRunner.expectEqual(
            extracted("Meeting link: https://company.zoom.us/j/987654321"),
            "https://company.zoom.us/j/987654321"
        )
    }

    TestRunner.test("keeps dots and dashes in Zoom pwd tokens") {
        TestRunner.expectEqual(
            extracted("https://zoom.us/j/123?pwd=abc.def-ghi"),
            "https://zoom.us/j/123?pwd=abc.def-ghi"
        )
    }

    // MARK: Google Meet

    TestRunner.test("extracts Google Meet URL") {
        TestRunner.expectEqual(
            extracted("Join: https://meet.google.com/abc-defg-hij"),
            "https://meet.google.com/abc-defg-hij"
        )
    }

    // MARK: Microsoft Teams

    TestRunner.test("keeps the context query on Teams URLs") {
        let link = "https://teams.microsoft.com/l/meetup-join/19%3ameeting_ABC%40thread.v2/0?context=%7b%22Tid%22%3a%22x%22%7d"
        TestRunner.expectEqual(extracted("Teams meeting: \(link)"), link)
    }

    // MARK: Other providers

    TestRunner.test("extracts WebEx URL") {
        TestRunner.expectEqual(
            extracted("WebEx: https://company.webex.com/meet/john.doe"),
            "https://company.webex.com/meet/john.doe"
        )
    }

    TestRunner.test("extracts Whereby URL") {
        TestRunner.expectEqual(
            extracted("Let's meet at https://whereby.com/my-room"),
            "https://whereby.com/my-room"
        )
    }

    TestRunner.test("extracts full Around URL path") {
        // Regression: the old pattern stopped at the first path segment,
        // truncating this to https://around.co/r
        TestRunner.expectEqual(
            extracted("Around room: https://around.co/r/team-standup"),
            "https://around.co/r/team-standup"
        )
    }

    TestRunner.test("extracts Discord invite URL") {
        TestRunner.expectEqual(
            extracted("Discord: https://discord.gg/abc123"),
            "https://discord.gg/abc123"
        )
    }

    TestRunner.test("extracts Discord channel URL") {
        TestRunner.expectEqual(
            extracted("Channel: https://discord.com/channels/123456/789012"),
            "https://discord.com/channels/123456/789012"
        )
    }

    TestRunner.test("extracts Slack huddle URL") {
        TestRunner.expectEqual(
            extracted("Huddle: https://app.slack.com/huddle/T123/C456"),
            "https://app.slack.com/huddle/T123/C456"
        )
    }

    TestRunner.test("extracts Jitsi URL") {
        TestRunner.expectEqual(
            extracted("Jitsi Meet: https://meet.jit.si/MyMeetingRoom"),
            "https://meet.jit.si/MyMeetingRoom"
        )
    }

    // MARK: Edge cases

    TestRunner.test("returns nil when no URL present") {
        TestRunner.expect(extracted("This is just a regular meeting description with no links") == nil)
    }

    TestRunner.test("first matching URL wins within a text") {
        TestRunner.expectEqual(
            extracted("Primary: https://zoom.us/j/111 Backup: https://meet.google.com/xyz"),
            "https://zoom.us/j/111"
        )
    }

    TestRunner.test("searches multiple texts in order") {
        let url = MeetingURLExtractor.extractURL(from: [
            nil,
            "Conference Room 4",
            "Video: https://meet.google.com/abc-defg-hij"
        ])
        TestRunner.expectEqual(url?.absoluteString, "https://meet.google.com/abc-defg-hij")
    }
}
