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
                    .padding(.vertical, 4)
                    .tag(tab)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 180, max: 180)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            pane
            .navigationTitle("")
            .background {
                VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                    .ignoresSafeArea()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 740, minHeight: 680)
        .onChange(of: settings) { previous, newSettings in
            downloadManager.settingsChanged(newSettings, previous: previous)
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
        case .trackers:
            TrackersSettingsPane()
        case .network:
            NetworkSettingsPane()
        case .video:
            VideoSettingsPane()
        }
    }
}
