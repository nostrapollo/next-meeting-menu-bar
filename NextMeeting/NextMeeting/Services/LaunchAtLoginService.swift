import ServiceManagement
import SwiftUI
import os

@MainActor
class LaunchAtLoginService: ObservableObject {
    private static let logger = Logger(subsystem: "com.nextmeeting.app", category: "LaunchAtLogin")

    @Published var isEnabled: Bool {
        didSet {
            setLaunchAtLogin(isEnabled)
        }
    }

    init() {
        self.isEnabled = SMAppService.mainApp.status == .enabled
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            Self.logger.error("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
        }
    }
}
