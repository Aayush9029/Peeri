import Models
import Shared
import SwiftUI

struct ContentView: View {
    @Environment(DownloadManager.self) private var downloadManager
    @Environment(AppUIModel.self) private var appUI

    @State private var selectedFilter: DownloadFilter? = .all
    @State private var selectedDownloadIDs: Set<DownloadFile.ID> = []
    @State private var detailDownload: DownloadFile?

    private var filteredDownloads: [DownloadFile] {
        (selectedFilter ?? .all).filter(downloadManager.downloads)
    }

    private var selectedDownload: DownloadFile? {
        guard let id = selectedDownloadIDs.first else { return nil }
        return downloadManager.downloads.first { $0.id == id }
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
            DownloadTable(
                downloads: filteredDownloads,
                selection: $selectedDownloadIDs,
                detailDownload: $detailDownload
            )
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    DownloadStatsFooter(allPaused: allPaused)
                }
                .frame(minWidth: 560)
        }
        .toolbar {
            if let selectedDownload {
                ToolbarItemGroup(placement: .navigation) {
                    Button {
                        downloadManager.openDownload(selectedDownload)
                    } label: {
                        Label("Open", systemImage: "arrow.up.right.square")
                            .labelStyle(.titleAndIcon)
                    }
                    .keyboardShortcut("o", modifiers: .command)
                    .help("Open (⌘O)")

                    Button {
                        detailDownload = selectedDownload
                    } label: {
                        Label("Get Info", systemImage: "info.circle")
                            .labelStyle(.iconOnly)
                    }
                    .keyboardShortcut("i", modifiers: .command)
                    .help("Get Info (⌘I)")
                }

                ToolbarItemGroup(placement: .automatic) {
                    Button {
                        downloadManager.showInFinder(selectedDownload)
                    } label: {
                        Label("Show in Finder", systemImage: "folder")
                            .labelStyle(.titleAndIcon)
                    }
                    .keyboardShortcut("r", modifiers: .command)
                    .help("Show in Finder (⌘R)")

                    Button {
                        downloadManager.copyFilePath(selectedDownload)
                    } label: {
                        Label("Copy Path", systemImage: "doc.on.doc")
                            .labelStyle(.titleAndIcon)
                    }
                    .keyboardShortcut("c", modifiers: .command)
                    .help("Copy Path (⌘C)")
                }

                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        delete(selectedDownload)
                    } label: {
                        Label(deleteTitle(for: selectedDownload), systemImage: "trash")
                            .labelStyle(.iconOnly)
                    }
                    .keyboardShortcut(.delete, modifiers: [])
                    .help("\(deleteTitle(for: selectedDownload)) (Delete)")
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    appUI.isAddDownloadPresented = true
                } label: {
                    Label("Add Download", systemImage: "plus")
                        .labelStyle(.iconOnly)
                }
                .help("Add Download (⌘N)")
            }
        }
        .sheet(isPresented: $appUI.isAddDownloadPresented) {
            AddDownloadView()
                .environment(downloadManager)
        }
    }

    private func delete(_ download: DownloadFile) {
        switch download.status {
        case .downloading, .paused, .pending:
            Task { await downloadManager.cancelDownload(download) }
        case .completed, .failed, .seeding, .removed:
            downloadManager.removeDownload(download)
        }

        selectedDownloadIDs.remove(download.id)
        if detailDownload?.id == download.id {
            detailDownload = nil
        }
    }

    private func deleteTitle(for download: DownloadFile) -> String {
        switch download.status {
        case .downloading, .paused, .pending:
            return "Cancel"
        case .completed, .failed, .seeding, .removed:
            return "Remove"
        }
    }
}

#if DEBUG
#Preview {
    ContentView()
        .environment(DownloadManager.preview())
        .environment(AppUIModel())
        .frame(width: 900, height: 600)
}
#endif
