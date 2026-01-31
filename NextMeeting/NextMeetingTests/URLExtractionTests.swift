import XCTest
@testable import NextMeeting

final class URLExtractionTests: XCTestCase {
    
    // MARK: - Zoom URL Tests
    
    func testExtractsZoomURL() {
        let text = "Join us at https://zoom.us/j/123456789?pwd=abc123"
        let url = extractURL(from: text)
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("zoom.us") ?? false)
    }
    
    func testExtractsZoomVanityURL() {
        let text = "Meeting link: https://company.zoom.us/j/987654321"
        let url = extractURL(from: text)
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("zoom.us") ?? false)
    }
    
    // MARK: - Google Meet Tests
    
    func testExtractsGoogleMeetURL() {
        let text = "Join: https://meet.google.com/abc-defg-hij"
        let url = extractURL(from: text)
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("meet.google.com") ?? false)
    }
    
    // MARK: - Microsoft Teams Tests
    
    func testExtractsTeamsURL() {
        let text = "Teams meeting: https://teams.microsoft.com/l/meetup-join/abc123%2Fdef456"
        let url = extractURL(from: text)
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("teams.microsoft.com") ?? false)
    }
    
    // MARK: - WebEx Tests
    
    func testExtractsWebExURL() {
        let text = "WebEx: https://company.webex.com/meet/john.doe"
        let url = extractURL(from: text)
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("webex.com") ?? false)
    }
    
    // MARK: - Whereby Tests
    
    func testExtractsWherebyURL() {
        let text = "Let's meet at https://whereby.com/my-room"
        let url = extractURL(from: text)
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("whereby.com") ?? false)
    }
    
    // MARK: - Around Tests
    
    func testExtractsAroundURL() {
        let text = "Around room: https://around.co/r/team-standup"
        let url = extractURL(from: text)
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("around.co") ?? false)
    }
    
    // MARK: - Discord Tests
    
    func testExtractsDiscordInviteURL() {
        let text = "Discord: https://discord.gg/abc123"
        let url = extractURL(from: text)
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("discord.gg") ?? false)
    }
    
    func testExtractsDiscordChannelURL() {
        let text = "Channel: https://discord.com/channels/123456/789012"
        let url = extractURL(from: text)
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("discord.com") ?? false)
    }
    
    // MARK: - Slack Huddle Tests
    
    func testExtractsSlackHuddleURL() {
        let text = "Huddle: https://app.slack.com/huddle/T123/C456"
        let url = extractURL(from: text)
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("slack.com/huddle") ?? false)
    }
    
    // MARK: - Jitsi Tests
    
    func testExtractsJitsiURL() {
        let text = "Jitsi Meet: https://meet.jit.si/MyMeetingRoom"
        let url = extractURL(from: text)
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("meet.jit.si") ?? false)
    }
    
    // MARK: - Edge Cases
    
    func testReturnsNilForNoURL() {
        let text = "This is just a regular meeting description with no links"
        let url = extractURL(from: text)
        XCTAssertNil(url)
    }
    
    func testExtractsFirstMatchingURL() {
        let text = "Primary: https://zoom.us/j/111 Backup: https://meet.google.com/xyz"
        let url = extractURL(from: text)
        XCTAssertNotNil(url)
        // Should extract the first matching URL
        XCTAssertTrue(url?.absoluteString.contains("zoom.us") ?? false)
    }
    
    // MARK: - Helper
    
    /// Simulates the URL extraction logic from CalendarService
    private func extractURL(from text: String) -> URL? {
        let patterns = [
            #"https?://[\w.-]*zoom\.us/j/[\d\w?=&]+"#,
            #"https?://meet\.google\.com/[\w-]+"#,
            #"https?://teams\.microsoft\.com/l/meetup-join/[\w%/-]+"#,
            #"https?://[\w.-]+\.webex\.com/[\w/.-]+"#,
            #"https?://whereby\.com/[\w-]+"#,
            #"https?://around\.co/[\w/-]+"#,
            #"https?://discord\.gg/[\w]+"#,
            #"https?://discord\.com/channels/[\d/]+"#,
            #"https?://app\.slack\.com/huddle/[\w/]+"#,
            #"https?://meet\.jit\.si/[\w-]+"#
        ]
        
        for pattern in patterns {
            if let url = findURL(matching: pattern, in: text) {
                return url
            }
        }
        
        return nil
    }
    
    private func findURL(matching pattern: String, in text: String) -> URL? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(text.startIndex..., in: text)
        if let match = regex.firstMatch(in: text, options: [], range: range) {
            if let matchRange = Range(match.range, in: text) {
                let urlString = String(text[matchRange])
                return URL(string: urlString)
            }
        }
        
        return nil
    }
}
