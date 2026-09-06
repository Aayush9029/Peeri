import SwiftUI

struct TransferCommands: Commands {
    let showPalette: () -> Void
    let pauseAll: () -> Void
    let resumeAll: () -> Void
    @FocusedValue(\.transferSelection) private var selection

    var body: some Commands {
        CommandMenu("Transfers") {
            Button("Command Palette…", action: showPalette)
                .keyboardShortcut("k", modifiers: .command)
            Divider()
            Button("Open Download") { selection?.open() }
                .keyboardShortcut("o", modifiers: .command)
                .disabled(selection?.canReveal != true)
            Button("Get Info") { selection?.inspect() }
                .keyboardShortcut("i", modifiers: .command)
                .disabled(selection?.canInspect != true)
            Button("Show in Finder") { selection?.reveal() }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(selection?.canReveal != true)
            Divider()
            Button("Pause All", action: pauseAll)
            Button("Resume All", action: resumeAll)
            Divider()
            Button("Remove Download") { selection?.remove() }
                .keyboardShortcut(.delete, modifiers: [])
                .disabled(selection?.canInspect != true)
        }
    }
}
