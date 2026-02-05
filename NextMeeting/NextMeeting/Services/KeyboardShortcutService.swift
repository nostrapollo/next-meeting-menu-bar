import Cocoa
import Carbon
import SwiftUI

@MainActor
class KeyboardShortcutService: ObservableObject {
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
    
    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyID = EventHotKeyID(signature: 0x4A4D4E4D, id: 1) // JMNM = Join Meeting Next Meeting
    private var eventHandler: EventHandlerRef?
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
    
    private func registerHotkey() {
        // Unregister existing hotkey if any
        unregisterHotkey()
        
        // Convert Carbon modifiers to EventHotKey modifiers
        var carbonModifiers: UInt32 = 0
        
        if modifiers & UInt32(cmdKey) != 0 {
            carbonModifiers |= UInt32(cmdKey)
        }
        if modifiers & UInt32(shiftKey) != 0 {
            carbonModifiers |= UInt32(shiftKey)
        }
        if modifiers & UInt32(optionKey) != 0 {
            carbonModifiers |= UInt32(optionKey)
        }
        if modifiers & UInt32(controlKey) != 0 {
            carbonModifiers |= UInt32(controlKey)
        }
        
        // Create event spec for hotkey
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                       eventKind: UInt32(kEventHotKeyPressed))
        
        // Install event handler
        let handler: EventHandlerUPP = { _, event, userData in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            
            // Extract the service from userData
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
        
        // Install the event handler
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(),
                           handler,
                           1,
                           &eventType,
                           selfPtr,
                           &eventHandler)
        
        // Register the hotkey
        var hotKeyRefTemp: EventHotKeyRef?
        let status = RegisterEventHotKey(UInt32(keyCode),
                                        carbonModifiers,
                                        hotKeyID,
                                        GetApplicationEventTarget(),
                                        0,
                                        &hotKeyRefTemp)
        
        if status == noErr {
            hotKeyRef = hotKeyRefTemp
            print("✓ Global keyboard shortcut registered: ⌘⇧J")
        } else {
            print("✗ Failed to register global keyboard shortcut: \(status)")
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
