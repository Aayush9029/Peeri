import Models
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var downloadManager: DownloadManager
    @State private var showAddDownload = false
    @State private var downloadURL = ""
    
    @State private var selectedFilter: DownloadFilter = .all
    
    private var filteredDownloads: [DownloadFile] {
        selectedFilter.filter(downloadManager.downloads)
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    HStack {
                        Text("Peeri")
                            .bold()
                        Spacer()
                    }
                    .padding(.bottom)
                    SideBar(
                        selectedFilter: $selectedFilter,
                        activeCount: downloadManager.activeDownloads.count,
                        pausedCount: downloadManager.pausedDownloads.count,
                        completedCount: downloadManager.completedDownloads.count,
                        connectionState: downloadManager.connectionState
                    )
                    Spacer()
                    
                    // Add Download Button
                    Button(action: {
                        showAddDownload.toggle()
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Download")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
//                    .disabled(
//                        if case .connected = downloadManager.connectionState {
//                            false
//                        } else {
//                            true
//                        }
//                    )
                }
                .frame(width: 256)
                .padding(.horizontal, 8)
                .padding(.vertical)
                .background(.gray.opacity(0.012))
                .cornerRadius(16)
                
                VStack {
                    if let error = downloadManager.lastError,
                       case .failed = downloadManager.connectionState
                    {
                        ConnectionErrorView(errorMessage: error)
                    } else {
                        DownloadListView(downloads: filteredDownloads)
                        Divider()
                            .padding(.vertical)
                        TransferStatsView(
                            downloadRate: downloadManager.totalDownloadRate,
                            uploadRate: downloadManager.totalUploadRate
                        )
                        .frame(height: 320)
                        .padding()
                    }
                }
            }
        }
        .padding(8)
        .padding(.top)
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
        .ignoresSafeArea()
        .sheet(isPresented: $showAddDownload) {
            AddDownloadView(isPresented: $showAddDownload, downloadManager: downloadManager)
        }
    }
}

struct DownloadListView: View {
    let downloads: [DownloadFile]
    
    var body: some View {
        VStack {
            if downloads.isEmpty {
                VStack {
                    Spacer()
                    Text("No downloads yet")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("Add a download to get started")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ForEach(downloads) { download in
                    DownloadRow(download: download)
                }
            }
        }
    }
}

struct DownloadRow: View {
    let download: DownloadFile
    
    var body: some View {
        VStack {
            HStack {
                HStack {
                    HStack {
                        statusIcon
                        Text(download.fileName)
                            .lineLimit(1)
                        Spacer()
                    }
                    .font(.title3)
                    .frame(width: 256)
                    
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 12)
                            .frame(width: 200, height: 6)
                            .foregroundStyle(.quaternary)
                        RoundedRectangle(cornerRadius: 12)
                            .fill(statusColor.gradient)
                            .frame(width: 200 * download.progress, height: 6)
                    }
                    .frame(width: 248)
                    
                    HStack {
                        Text(formattedFileSize)
                        Spacer()
                    }
                    .frame(width: 72)
                    
                    HStack {
                        Text(statusText)
                        Spacer()
                    }
                    .frame(width: 128)
                }
                .font(.title3)
                .lineLimit(1)
                .padding(12)
                .opacity(download.status == .paused ? 0.75 : 1)
                .background(.gray.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }
    
    private var statusIcon: some View {
        switch download.status {
            case .downloading:
                return Image(systemName: "arrow.down")
            case .paused:
                return Image(systemName: "pause")
            case .completed:
                return Image(systemName: "checkmark")
            case .pending:
                return Image(systemName: "hourglass")
            case .failed:
                return Image(systemName: "exclamationmark.triangle")
        }
    }
    
    private var statusColor: Color {
        switch download.status {
            case .downloading:
                return .blue
            case .paused:
                return .gray
            case .completed:
                return .green
            case .pending:
                return .orange
            case .failed:
                return .red
        }
    }
    
    private var statusText: String {
        switch download.status {
            case .downloading:
                return "Downloading"
            case .paused:
                return "Paused"
            case .completed:
                return "Completed"
            case .pending:
                return "Pending"
            case .failed:
                return "Failed"
        }
    }
    
    private var formattedFileSize: String {
        guard let size = download.fileSize else { return "Unknown" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

struct TransferStatsView: View {
    let downloadRate: Int64
    let uploadRate: Int64
    
    var body: some View {
        HStack {
            ZStack {
                TransferChart(numbers: [0.35, 0.18, 0.2], tint: .blue)
            }
            VStack(alignment: .leading) {
                Text("DOWNLOAD / UPLOAD PER SEC")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack {
                    HStack {
                        Image(systemName: "arrow.down")
                        Text(formattedDownloadRate)
                    }
                    Spacer()
                    HStack {
                        Image(systemName: "arrow.up")
                        Text(formattedUploadRate)
                    }
                }
                .font(.title.bold())
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading) {
                            Text("Total Downloaded")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("0 MB")
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Total Uploaded")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("0 MB")
                        }
                    }
                    Spacer()
                }
                .font(.title2)
                Spacer()
            }.padding()
        }
    }
    
    private var formattedDownloadRate: String {
        ByteCountFormatter.string(fromByteCount: downloadRate, countStyle: .binary) + "/s"
    }
    
    private var formattedUploadRate: String {
        ByteCountFormatter.string(fromByteCount: uploadRate, countStyle: .binary) + "/s"
    }
}

struct AddDownloadView: View {
    @Binding var isPresented: Bool
    @State private var url: String = ""
    let downloadManager: DownloadManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Download")
                .font(.title)
                .padding(.top)
            
            TextField("Enter URL", text: $url)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Button("Add") {
                    if let downloadURL = URL(string: url) {
                        Task {
                            await downloadManager.addDownload(url: downloadURL)
                            isPresented = false
                        }
                    }
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(url.isEmpty || URL(string: url) == nil)
            }
            .padding(.bottom)
        }
        .frame(width: 400, height: 200)
    }
}

struct ConnectionErrorView: View {
    let errorMessage: String
    
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: "exclamationmark.icloud.fill")
                .font(.system(size: 64))
                .foregroundColor(.red)
                .padding()
            
            Text("Connection Error")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 4)
            
            Text(errorMessage)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Text("The app will automatically try to reconnect...")
                .font(.callout)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DownloadManager())
    }
}
