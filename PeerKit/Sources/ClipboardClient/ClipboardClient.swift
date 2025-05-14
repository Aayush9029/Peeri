import AppKit
import Dependencies
import os.log
@_exported import Sauce

public struct ClipboardClient {
    public var copyToClipboard: () -> Void
    public var pasteFromClipboard: () -> Void
    public var getClipboardContent: () -> String?
    public var setClipboardContent: (String) -> Void
    public var saveCurrentClipboard: () -> String?
    public var restoreClipboard: (String?) -> Void
}

extension ClipboardClient: DependencyKey {
    public static var liveValue: Self {
        let pasteboard = NSPasteboard.general
        let logger = Logger(subsystem: "com.lovedoingthings.peeri", category: "📋")
        
        return Self(
            copyToClipboard: {
                logger.info("Simulating Command+C")
                let src = CGEventSource(stateID: .hidSystemState)
                
                let cKeyCode = Sauce.shared.keyCode(for: .c)
                let keyDown = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(cKeyCode), keyDown: true)
                let keyUp = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(cKeyCode), keyDown: false)
                
                keyDown?.flags = .maskCommand
                keyUp?.flags = .maskCommand
                
                keyDown?.post(tap: .cghidEventTap)
                keyUp?.post(tap: .cghidEventTap)
                
                // Small delay to ensure copy completes
                Thread.sleep(forTimeInterval: 0.1)
            },
            pasteFromClipboard: {
                logger.info("Simulating Command+V")
                let src = CGEventSource(stateID: .hidSystemState)
                
                let vKeyCode = Sauce.shared.keyCode(for: .v)
                let keyDown = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(vKeyCode), keyDown: true)
                let keyUp = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(vKeyCode), keyDown: false)
                
                keyDown?.flags = .maskCommand
                keyUp?.flags = .maskCommand
                
                keyDown?.post(tap: .cghidEventTap)
                keyUp?.post(tap: .cghidEventTap)
                
                // Small delay to ensure paste completes
                Thread.sleep(forTimeInterval: 0.1)
            },
            getClipboardContent: {
                logger.info("Getting clipboard content")
                return pasteboard.string(forType: .string)
            },
            setClipboardContent: { content in
                logger.info("Setting clipboard content")
                pasteboard.clearContents()
                pasteboard.setString(content, forType: .string)
            },
            saveCurrentClipboard: {
                logger.info("Saving current clipboard")
                return pasteboard.string(forType: .string)
            },
            restoreClipboard: { content in
                logger.info("Restoring clipboard")
                pasteboard.clearContents()
                if let content {
                    pasteboard.setString(content, forType: .string)
                }
            }
        )
    }
}

public extension DependencyValues {
    var clipboardClient: ClipboardClient {
        get { self[ClipboardClient.self] }
        set { self[ClipboardClient.self] = newValue }
    }
}