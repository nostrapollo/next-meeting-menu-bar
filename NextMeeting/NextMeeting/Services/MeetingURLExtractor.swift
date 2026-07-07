import Foundation

/// Extracts video-call URLs from free-form event text (URL field, location, notes).
/// Pure logic with no EventKit dependency so it can be unit tested directly.
enum MeetingURLExtractor {

    /// Ordered by how specific the pattern is; first match across all texts wins.
    static let patterns = [
        // Zoom, including vanity subdomains (company.zoom.us) and ?pwd= tokens,
        // which may contain '.' and '-'.
        #"https?://[\w.-]*zoom\.us/j/\d+(?:\?[\w=&.%-]+)?"#,
        #"https?://meet\.google\.com/[\w-]+"#,
        // Teams links need their ?context=... query to join correctly.
        #"https?://teams\.microsoft\.com/l/meetup-join/[\w%/.-]+(?:\?[\w=&%.-]+)?"#,
        #"https?://[\w.-]+\.webex\.com/[\w/.-]+"#,
        #"https?://whereby\.com/[\w-]+"#,
        #"https?://around\.co/[\w/-]+"#,
        #"https?://discord\.gg/[\w-]+"#,
        #"https?://discord\.com/channels/[\d/]+"#,
        #"https?://app\.slack\.com/huddle/[\w/-]+"#,
        #"https?://meet\.jit\.si/[\w-]+"#
    ]

    /// Returns the first meeting URL found in any of the given texts.
    /// Texts are searched in order, and within each text patterns are tried in order.
    static func extractURL(from texts: [String?]) -> URL? {
        for text in texts.compactMap({ $0 }) {
            for pattern in patterns {
                if let url = firstURL(matching: pattern, in: text) {
                    return url
                }
            }
        }
        return nil
    }

    private static func firstURL(matching pattern: String, in text: String) -> URL? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let matchRange = Range(match.range, in: text) else {
            return nil
        }

        return URL(string: String(text[matchRange]))
    }
}
