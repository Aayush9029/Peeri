import Models
import Shared
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(DownloadManager.self) var downloadManager
    @State private var showAddDownload = false
    @State private var selectedFilter: DownloadFilter = .all
    @State private var sidebarCollapsed = false
    @State private var statsCollapsed = false

    private var filteredDownloads: [DownloadFile] {
        selectedFilter.filter(downloadManager.downloads)
    }

    private var allPaused: Bool {
        let active = downloadManager.downloads.filter { $0.status == .downloading || $0.status == .seeding }
        return active.isEmpty && !downloadManager.downloads.isEmpty
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
                ZStack(alignment: .bottomTrailing) {
                    contentPanel
                    floatingAddButton
                        .padding(.trailing, 24)
                        .padding(.bottom, statsCollapsed ? 56 : 24)
                }
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
        }
    }

    // MARK: - Floating Add Button

    private var floatingAddButton: some View {
        Button { showAddDownload.toggle() } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(.black)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
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
                downloads: downloadManager.downloads
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
        VStack(spacing: 0) {
            DownloadListView(downloads: filteredDownloads)

            // Divider with toggle button
            ZStack {
                Divider()
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        statsCollapsed.toggle()
                    }
                } label: {
                    Image(systemName: statsCollapsed ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 16)
                        .background(.bar)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)

            if statsCollapsed {
                // Compact inline stats bar
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text(ByteCountFormatter.string(fromByteCount: downloadManager.totalDownloadRate, countStyle: .binary) + "/s")
                            .font(.callout.monospacedDigit())
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text(ByteCountFormatter.string(fromByteCount: downloadManager.totalUploadRate, countStyle: .binary) + "/s")
                            .font(.callout.monospacedDigit())
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 32)
                .transition(.opacity)
            } else {
                TransferStatsView(
                    downloadRate: downloadManager.totalDownloadRate,
                    uploadRate: downloadManager.totalUploadRate,
                    downloadHistory: downloadManager.downloadSpeedHistory,
                    uploadHistory: downloadManager.uploadSpeedHistory,
                    totalDownloaded: downloadManager.sessionDownloaded,
                    totalUploaded: downloadManager.sessionUploaded,
                    allPaused: allPaused
                )
                .frame(height: 320)
                .padding()
                .transition(.opacity)
            }
        }
    }
}
