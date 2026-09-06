import Models
import Shared
import SwiftUI
import UI

struct ContentView: View {
    @Environment(DownloadManager.self) private var downloadManager
    @Environment(AppUIModel.self) private var appUI
    @Environment(\.openWindow) private var openWindow
    @State private var searchText = ""

    @State private var selectedFilter: DownloadFilter? = .all
    @State private var selectedDownloadIDs: Set<DownloadFile.ID> = []
    @State private var detailDownload: DownloadFile?
    @State private var isInspectorPresented = false

    private var filteredDownloads: [DownloadFile] {
        (selectedFilter ?? .all).filter(downloadManager.downloads).filter {
            searchText.isEmpty || $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
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
            HSplitView {
                DownloadTable(
                    downloads: filteredDownloads,
                    emptyTitle: emptyTitle,
                    emptyDescription: emptyDescription,
                    selection: $selectedDownloadIDs,
                    showDetail: { detailDownload = $0; isInspectorPresented = true }
                )
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    DownloadStatsFooter(allPaused: allPaused)
                }
                .frame(minWidth: 560)
                .navigationTitle((selectedFilter ?? .all) == .all ? "Peeri" : (selectedFilter ?? .all).rawValue)
                .background {
                    VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                        .ignoresSafeArea()
                }
                if isInspectorPresented, let detailDownload {
                    VStack(spacing: 0) {
                        if !detailDownload.isVideoDownload {
                            HStack {
                                Text("Details").font(.headline)
                                Spacer()
                                Button { isInspectorPresented = false } label: {
                                    Image(systemName: "xmark")
                                }
                                .buttonStyle(.borderless)
                                .help("Close Details")
                                .accessibilityLabel("Close Details")
                            }
                            .padding(16)
                        }
                        DownloadInspectorView(downloadID: detailDownload.id)
                            .id(detailDownload.id)
                    }
                    .frame(minWidth: 320, idealWidth: 380, maxWidth: 480)
                    .universalGlassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(alignment: .topTrailing) {
                        if detailDownload.isVideoDownload {
                            Button { isInspectorPresented = false } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .universalGlassEffect(.clear.tint(.black.opacity(0.22)).interactive(), in: Circle())
                            }
                            .buttonStyle(.plain)
                            .help("Close Details")
                            .accessibilityLabel("Close Details")
                            .padding(12)
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.white.opacity(0.12), lineWidth: 0.5)
                            .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: 16))
                    .padding(8)
                }
            }

        }
        .onChange(of: detailDownload?.id) { _, id in
            isInspectorPresented = id != nil
        }
        .onChange(of: selectedDownloadIDs) { _, _ in
            detailDownload = selectedDownload
        }
        .onChange(of: filteredDownloads.map(\.id)) { _, ids in
            selectedDownloadIDs.formIntersection(ids)
            if let detailDownload, !ids.contains(detailDownload.id) {
                self.detailDownload = nil
            }
        }
        .searchable(text: $searchText, prompt: "Search transfers")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { appUI.present(.addDownload) } label: {
                    Label("Add Download", systemImage: "square.and.arrow.down")
                }
                .help("Add Download (⌘N)")

                if selectionCanToggle {
                    Button { toggleSelectedTransfers() } label: {
                        Label(selectionCanResume ? "Resume" : "Pause", systemImage: selectionCanResume ? "play.fill" : "pause.fill")
                    }
                    .help(selectionCanResume ? "Resume Selected Transfers" : "Pause Selected Transfers")
                }
            }
        }
        .focusedSceneValue(\.transferSelection, TransferSelectionActions(
            canInspect: selectedDownload != nil,
            canReveal: selectedDownload.map { downloadManager.resolvedFileURL(for: $0) != nil } ?? false,
            inspect: { detailDownload = selectedDownload; isInspectorPresented = selectedDownload != nil },
            reveal: { if let selectedDownload { downloadManager.showInFinder(selectedDownload) } },
            remove: removeSelectedTransfers,
            open: { if let selectedDownload { downloadManager.openDownload(selectedDownload) } }
        ))
        .sheet(isPresented: $appUI.isPanelPresented) {
            CommandPaletteView(commands: commands, initialPage: appUI.panelPage)
                .environment(downloadManager)
                .presentationBackground(.clear)
        }
        .safeAreaInset(edge: .top) {
            if let error = downloadManager.lastError {
                HStack {
                    Label(error, systemImage: "exclamationmark.triangle")
                    Spacer()
                    Button("Dismiss") { downloadManager.lastError = nil }
                }
                .font(.callout)
                .padding(12)
                .background(.orange.opacity(0.12))
            }
        }
    }

    private var commands: [PeeriCommand] {
        var result: [PeeriCommand] = [
            .init(id: "new", title: "Add Download…", symbol: "arrow.down.circle", shortcut: "⌘N", downloadInput: "") {},
            .init(id: "pause", title: "Pause All Transfers", symbol: "pause") { Task { await downloadManager.pauseAll() } },
            .init(id: "resume", title: "Resume All Transfers", symbol: "play") { Task { await downloadManager.resumeAll() } },
            .init(id: "settings", title: "Open Settings", symbol: "slider.horizontal.3", shortcut: "⌘,") { openWindow(id: "settings") }
        ]
        for filter in DownloadFilter.allCases {
            result.append(.init(id: filter.rawValue, title: "Show \(filter.rawValue) Transfers", symbol: filter.icon) { selectedFilter = filter })
        }
        if let download = selectedDownload {
            if download.status == .failed {
                result.append(.init(id: "retrySelected", title: "Retry \(download.displayName)", symbol: "arrow.clockwise") { Task { await downloadManager.retryDownload(download) } })
            } else if download.status == .paused {
                result.append(.init(id: "resumeSelected", title: "Resume \(download.displayName)", symbol: "play") { Task { await downloadManager.resumeDownload(download) } })
            } else if [.downloading, .seeding].contains(download.status) && !download.isVideoDownload {
                result.append(.init(id: "pauseSelected", title: "Pause \(download.displayName)", symbol: "pause") { Task { await downloadManager.pauseDownload(download) } })
            }
            result.append(.init(id: "info", title: "Get Info: \(download.displayName)", symbol: "info.circle", shortcut: "⌘I") { detailDownload = download; isInspectorPresented = true })
        }
        return result
    }

    private var emptyTitle: String {
        if !searchText.isEmpty { return "No matching downloads" }
        return selectedFilter == .all ? "No downloads yet" : "No \((selectedFilter ?? .all).rawValue.lowercased()) downloads"
    }

    private var emptyDescription: String {
        if !searchText.isEmpty { return "Try a different name or clear the search." }
        return selectedFilter == .all ? "Add a link or open a torrent to get started." : "Downloads with this status will appear here."
    }

    private var selectedTransfers: [DownloadFile] {
        downloadManager.downloads.filter { selectedDownloadIDs.contains($0.id) }
    }

    private var selectionCanResume: Bool {
        !selectedTransfers.isEmpty && selectedTransfers.allSatisfy { $0.status == .paused }
    }

    private var selectionCanToggle: Bool {
        selectedTransfers.contains { !$0.isVideoDownload && [.downloading, .seeding, .paused, .pending].contains($0.status) }
    }

    private func toggleSelectedTransfers() {
        let transfers = selectedTransfers
        let resume = selectionCanResume
        Task {
            for transfer in transfers where !transfer.isVideoDownload {
                if resume {
                    await downloadManager.resumeDownload(transfer)
                } else if [.downloading, .seeding, .pending].contains(transfer.status) {
                    await downloadManager.pauseDownload(transfer)
                }
            }
        }
    }

    private func removeSelectedTransfers() {
        let transfers = selectedTransfers
        Task {
            for transfer in transfers { await downloadManager.removeDownload(transfer) }
        }
        selectedDownloadIDs.removeAll()
        detailDownload = nil
    }

}
