import Cocoa
import Carbon
import SwiftUI
import os

@MainActor
class KeyboardShortcutService: ObservableObject {
    private static let logger = Logger(subsystem: "com.nextmeeting.app", category: "KeyboardShortcut")

    private enum Keys {
        static let shortcutEnabled = "keyboardShortcutEnabled"
        static let shortcutKeyCode = "keyboardShortcutKeyCode"
        static let shortcutModifiers = "keyboardShortcutModifiers"
    }
    
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Keys.shortcutEnabled)
            if isEnabled {
                registerHotkey()
            } else {
                unregisterHotkey()
            }
        }
    }
    
    // nonisolated(unsafe): touched from deinit, which is nonisolated under
    // strict concurrency. Safe because all real access happens on the main actor.
    nonisolated(unsafe) private var hotKeyRef: EventHotKeyRef?
    private var hotKeyID = EventHotKeyID(signature: 0x4A4D4E4D, id: 1) // JMNM = Join Meeting Next Meeting
    nonisolated(unsafe) private var eventHandler: EventHandlerRef?
    private var onTrigger: (() -> Void)?
    
    // Default: Command+Shift+J
    private let defaultKeyCode: UInt32 = UInt32(kVK_ANSI_J)
    private let defaultModifiers: UInt32 = UInt32(cmdKey | shiftKey)
    
    private var keyCode: UInt32
    private var modifiers: UInt32
    
    init() {
        // Load preferences
        let savedEnabled = UserDefaults.standard.object(forKey: Keys.shortcutEnabled)
        self.isEnabled = savedEnabled as? Bool ?? true
        
        let savedKeyCode = UserDefaults.standard.object(forKey: Keys.shortcutKeyCode) as? UInt32
        self.keyCode = savedKeyCode ?? defaultKeyCode
        
        let savedModifiers = UserDefaults.standard.object(forKey: Keys.shortcutModifiers) as? UInt32
        self.modifiers = savedModifiers ?? defaultModifiers
    }
    
    func setup(onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger
        
        if isEnabled {
            registerHotkey()
        }
    }
    
    /// The stored modifier mask, filtered to the Carbon modifier bits we support.
    private var carbonModifiers: UInt32 {
        var carbon: UInt32 = 0

        for flag in [cmdKey, shiftKey, optionKey, controlKey] where modifiers & UInt32(flag) != 0 {
            carbon |= UInt32(flag)
        }

        return carbon
    }

    /// Carbon hands the handler a raw pointer instead of a context, so this is a
    /// capture-free C function pointer that recovers the service from `userData`.
    private static let hotKeyEventHandler: EventHandlerUPP = { _, event, userData in
        guard let userData = userData else { return OSStatus(eventNotHandledErr) }

        let service = Unmanaged<KeyboardShortcutService>.fromOpaque(userData).takeUnretainedValue()

        // Verify this is our hotkey
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(event,
                                      UInt32(kEventParamDirectObject),
                                      UInt32(typeEventHotKeyID),
                                      nil,
                                      MemoryLayout<EventHotKeyID>.size,
                                      nil,
                                      &hotKeyID)

        if status == noErr && hotKeyID.id == service.hotKeyID.id {
            Task { @MainActor in
                service.onTrigger?()
            }
            return noErr
        }

        return OSStatus(eventNotHandledErr)
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                       eventKind: UInt32(kEventHotKeyPressed))

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(),
                           Self.hotKeyEventHandler,
                           1,
                           &eventType,
                           selfPtr,
                           &eventHandler)
    }

    private func registerHotkey() {
        // Unregister existing hotkey if any
        unregisterHotkey()
        installEventHandler()

        var hotKeyRefTemp: EventHotKeyRef?
        let status = RegisterEventHotKey(UInt32(keyCode),
                                        carbonModifiers,
                                        hotKeyID,
                                        GetApplicationEventTarget(),
                                        0,
                                        &hotKeyRefTemp)

        if status == noErr {
            hotKeyRef = hotKeyRefTemp
            Self.logger.info("Global keyboard shortcut registered: \(self.shortcutDisplayString)")
        } else {
            Self.logger.error("Failed to register global keyboard shortcut: \(status)")
        }
    }

    private func unregisterHotkey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
    
    deinit {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
    
    // Helper to get human-readable shortcut string
    var shortcutDisplayString: String {
        var components: [String] = []
        
        if modifiers & UInt32(cmdKey) != 0 {
            components.append("⌘")
        }
        if modifiers & UInt32(shiftKey) != 0 {
            components.append("⇧")
        }
        if modifiers & UInt32(optionKey) != 0 {
            components.append("⌥")
        }
        if modifiers & UInt32(controlKey) != 0 {
            components.append("⌃")
        }
        
        // Map key code to character
        let keyChar = keyCodeToString(keyCode)
        components.append(keyChar)
        
        return components.joined()
    }
    
    private func keyCodeToString(_ keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_Return: return "↵"
        case kVK_Space: return "Space"
        default: return "?"
        }
    }
}
