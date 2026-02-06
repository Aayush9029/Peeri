import Models
import Shared
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(DownloadManager.self) var downloadManager
    @State private var showAddDownload = false
    @State private var selectedFilter: DownloadFilter = .all
    @State private var sidebarCollapsed = false

    private var filteredDownloads: [DownloadFile] {
        selectedFilter.filter(downloadManager.downloads)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 4)

            // Main content
            HStack(spacing: 0) {
                // Sidebar
                if !sidebarCollapsed {
                    sidebarPanel
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }

                // Content area
                contentPanel
            }
            .animation(.easeInOut(duration: 0.25), value: sidebarCollapsed)
        }
        .padding(8)
        .padding(.top)
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
        .ignoresSafeArea()
        .sheet(isPresented: $showAddDownload) {
            AddDownloadView(isPresented: $showAddDownload, downloadManager: downloadManager)
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    sidebarCollapsed.toggle()
                }
            } label: {
                Image(systemName: "sidebar.left")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Text("Peeri")
                .font(.title3.bold())

            connectionDot

            Spacer()

            Button {
                showAddDownload.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Add Download")
                }
                .font(.callout)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }

    // MARK: - Connection Dot

    private var connectionDot: some View {
        Circle()
            .fill(connectionColor)
            .frame(width: 8, height: 8)
            .help(connectionTooltip)
    }

    private var connectionColor: Color {
        switch downloadManager.connectionState {
        case .connected: return .green
        case .connecting: return .orange
        case .disconnected: return .red
        case .failed: return .red
        }
    }

    private var connectionTooltip: String {
        switch downloadManager.connectionState {
        case .connected: return "Connected to aria2"
        case .connecting: return "Connecting..."
        case .disconnected: return "Disconnected"
        case .failed(let error): return "Error: \(error.localizedDescription)"
        }
    }

    // MARK: - Sidebar Panel

    private var sidebarPanel: some View {
        VStack {
            SideBar(
                selectedFilter: $selectedFilter,
                activeCount: downloadManager.activeDownloads.count,
                pausedCount: downloadManager.pausedDownloads.count,
                completedCount: downloadManager.completedDownloads.count
            )
            Spacer()
        }
        .frame(width: 220)
        .padding(.horizontal, 8)
        .padding(.vertical)
        .background(.gray.opacity(0.012))
        .cornerRadius(16)
    }

    // MARK: - Content Panel

    private var contentPanel: some View {
        VStack {
            DownloadListView(
                downloads: filteredDownloads,
                downloadManager: downloadManager
            )
            Divider()
                .padding(.vertical)
            TransferStatsView(
                downloadRate: downloadManager.totalDownloadRate,
                uploadRate: downloadManager.totalUploadRate,
                downloadHistory: downloadManager.downloadSpeedHistory,
                uploadHistory: downloadManager.uploadSpeedHistory,
                totalDownloaded: downloadManager.sessionDownloaded,
                totalUploaded: downloadManager.sessionUploaded,
                formatBytes: downloadManager.formatBytes
            )
            .frame(height: 320)
            .padding()
        }
    }
}
