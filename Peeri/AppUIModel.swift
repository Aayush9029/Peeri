import SwiftUI

enum CommandPanelPage {
    case commands
    case addDownload
}

@MainActor
@Observable
final class AppUIModel {
    var isPanelPresented = false
    var panelPage = CommandPanelPage.commands

    func present(_ page: CommandPanelPage) {
        panelPage = page
        isPanelPresented = true
    }
}
