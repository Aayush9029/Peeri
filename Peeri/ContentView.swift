import Models
import Shared
import SwiftUI

struct ContentView: View {
    @Environment(DownloadManager.self) private var downloadManager
    @Environment(AppUIModel.self) private var appUI

    @State private var selectedFilter: DownloadFilter? = .all
    @State private var statsCollapsed = false
    @State private var detailDownload: DownloadFile?

    private var filteredDownloads: [DownloadFile] {
        (selectedFilter ?? .all).filter(downloadManager.downloads)
    }

    private var allPaused: Bool {
        let active = downloadManager.downloads.filter { $0.status == .downloading || $0.status == .seeding }
        return active.isEmpty && !downloadManager.downloads.isEmpty
    }

    var body: some View {
        @Bindable var appUI = appUI

        NavigationSplitView {
            DownloadFilterSidebar(selection: $selectedFilter, downloads: downloadManager.downloads)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
        } detail: {
            VStack(spacing: 0) {
                DownloadListView(downloads: filteredDownloads) { detailDownload = $0 }
                DownloadStatsFooter(collapsed: $statsCollapsed, allPaused: allPaused)
            }
            .frame(minWidth: 560)
            .navigationTitle("Peeri")
            .toolbar {
                ToolbarItem(placement: .status) {
                    ConnectionStatusView(state: downloadManager.connectionState)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        appUI.isAddDownloadPresented = true
                    } label: {
                        Label("Add Download", systemImage: "plus")
                    }
                    .help("Add Download (⌘N)")
                }
            }
        }
        .sheet(isPresented: $appUI.isAddDownloadPresented) {
            AddDownloadView()
                .environment(downloadManager)
        }
        .sheet(item: $detailDownload) { download in
            DownloadDetailView(downloadID: download.id)
                .environment(downloadManager)
        }
    }
}

#Preview {
    ContentView()
        .environment(DownloadManager.preview())
        .environment(AppUIModel())
        .frame(width: 900, height: 600)
}
