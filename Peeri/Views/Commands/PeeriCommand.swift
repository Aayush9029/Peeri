import Foundation

struct PeeriCommand: Identifiable {
    let id: String
    let title: String
    var subtitle = ""
    let symbol: String
    var shortcut = ""
    var downloadInput: String?
    let action: @MainActor () -> Void
}
