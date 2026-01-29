import SwiftUI

struct MeetingAlertView: View {
    let meeting: Meeting
    let onDismiss: () -> Void
    let onJoin: ((URL) -> Void)?

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 80))
                    .foregroundColor(.white)

                VStack(spacing: 16) {
                    Text("Meeting Starting Now")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                    Text(meeting.title)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Text(meeting.timeString)
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.7))
                }

                HStack(spacing: 20) {
                    if let url = meeting.meetingURL {
                        Button(action: {
                            onJoin?(url)
                            onDismiss()
                        }) {
                            HStack {
                                Image(systemName: "video.fill")
                                Text("Join Meeting")
                            }
                            .font(.system(size: 20, weight: .semibold))
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .controlSize(.large)
                    }

                    Button(action: onDismiss) {
                        Text("Dismiss")
                            .font(.system(size: 20, weight: .medium))
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                    .controlSize(.large)
                }
                .padding(.top, 20)

                Spacer()

                Text("Press Escape or click Dismiss to close")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 40)
            }
        }
        .onExitCommand {
            onDismiss()
        }
    }
}

class MeetingAlertWindowController {
    private var window: NSWindow?
    private var eventMonitor: Any?

    func showAlert(for meeting: Meeting, onJoin: @escaping (URL) -> Void) {
        guard window == nil else { return }

        let alertView = MeetingAlertView(
            meeting: meeting,
            onDismiss: { [weak self] in
                self?.dismiss()
            },
            onJoin: onJoin
        )

        let hostingView = NSHostingView(rootView: alertView)

        let newWindow = NSWindow(
            contentRect: NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        newWindow.contentView = hostingView
        newWindow.level = .screenSaver
        newWindow.isOpaque = false
        newWindow.backgroundColor = .clear
        newWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        newWindow.isReleasedWhenClosed = false

        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.dismiss()
                return nil
            }
            return event
        }
    }

    func dismiss() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        window?.orderOut(nil)
        window = nil
    }
}
