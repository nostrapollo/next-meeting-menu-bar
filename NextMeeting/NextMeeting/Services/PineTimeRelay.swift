import Foundation
import os

/// Optional personal relay. The local watch API holds the ntfy credential.
@MainActor
final class PineTimeRelay {
    struct Payload: Encodable, Equatable {
        let clear: Bool
        let startEpoch: UInt32?
        let endEpoch: UInt32?
        let title: String?

        static func next(in meetings: [Meeting], now: Date) -> Payload {
            let remaining = meetings.filter { $0.endDate > now }
            let meeting = remaining.first { $0.startDate > now } ?? remaining.first
            guard let meeting,
                  let start = UInt32(exactly: meeting.startDate.timeIntervalSince1970.rounded(.down)),
                  let end = UInt32(exactly: meeting.endDate.timeIntervalSince1970.rounded(.down)),
                  start > 0, end > start else {
                return Payload(clear: true, startEpoch: nil, endEpoch: nil, title: nil)
            }
            return Payload(clear: false, startEpoch: start, endEpoch: end, title: String(meeting.title.prefix(1000)))
        }
    }

    private static let logger = Logger(subsystem: "com.nextmeeting.app", category: "PineTimeRelay")
    private var delivered: Payload?
    private var sending = false
    private var retryAfter = Date.distantPast

    func update(meetings: [Meeting], now: Date) {
        guard UserDefaults.standard.bool(forKey: "pineTimeRelayEnabled") else {
            delivered = nil
            return
        }
        let payload = Payload.next(in: meetings, now: now)
        guard !sending, payload != delivered, now >= retryAfter else { return }
        sending = true
        Task {
            defer { sending = false }
            do {
                guard let url = URL(string: "http://127.0.0.1:8787/meeting") else { return }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.timeoutInterval = 15
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(payload)
                let (_, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                delivered = payload
                retryAfter = .distantPast
            } catch {
                retryAfter = Date().addingTimeInterval(30)
                Self.logger.error("Watch relay unavailable; retrying in 30 seconds")
            }
        }
    }
}
