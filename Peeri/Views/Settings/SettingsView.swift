import Models
import Shared
import SwiftUI

struct SettingsView: View {
    @Environment(DownloadManager.self) private var downloadManager

    @Shared(.settings) private var settings
    @State private var selectedTab: SettingsTab = .general
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: sidebarSelection) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    HStack(spacing: 10) {
                        SettingsTabIcon(tab: tab, size: 20)
                        Text(tab.title)
                    }
                    .tag(tab)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 240)
        } detail: {
            pane
                .navigationTitle(selectedTab.title)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 740, minHeight: 680)
        .onChange(of: settings) { _, newSettings in
            Task { await downloadManager.applySettings(newSettings) }
        }
    }

    private var sidebarSelection: Binding<SettingsTab?> {
        Binding(get: { selectedTab }, set: { selectedTab = $0 ?? selectedTab })
    }

    @ViewBuilder
    private var pane: some View {
        switch selectedTab {
        case .general:
            GeneralSettingsPane()
        case .downloads:
            DownloadsSettingsPane()
        case .bitTorrent:
            BitTorrentSettingsPane()
        case .video:
            VideoSettingsPane()
        }
    }
}

#Preview {
    SettingsView()
        .environment(DownloadManager.preview())
}
