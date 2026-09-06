import Models
import SwiftUI
import UI

struct VideoDownloadInspectorView: View {
    let download: DownloadFile
    let artworkHeight: CGFloat

    @Environment(DownloadManager.self) private var downloadManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var canOpen: Bool {
        download.status == .completed && downloadManager.resolvedFileURL(for: download) != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if canOpen {
                Button { downloadManager.openDownload(download) } label: {
                    artwork
                        .overlay { VideoPlayControl() }
                }
                .buttonStyle(VideoPreviewButtonStyle())
                .help("Open video in your default player")
                .accessibilityLabel("Play \(download.displayName)")
            } else {
                artwork
            }

            VStack(alignment: .leading, spacing: 16) {
                Text(download.displayName)
                    .font(.system(size: 22, weight: .medium))
                    .lineLimit(4)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    if download.status == .completed {
                        Text(byteCount(download.downloadedSize))
                            .monospacedDigit()
                        if let filePath = download.filePath {
                            Text(URL(fileURLWithPath: filePath).pathExtension.uppercased())
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Spacer(minLength: 0)
                    Button { downloadManager.copyURL(download) } label: {
                        Image(systemName: "link")
                            .frame(width: 26, height: 26)
                    }
                    .help("Copy Video Link")
                    .accessibilityLabel("Copy Video Link")
                    if downloadManager.resolvedFileURL(for: download) != nil {
                        Button { downloadManager.showInFinder(download) } label: {
                            Image(systemName: "folder")
                                .frame(width: 26, height: 26)
                        }
                        .help("Show in Finder")
                        .accessibilityLabel("Show in Finder")
                    }
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(.secondary)

                if download.status == .failed {
                    HStack {
                        Label("Download failed", systemImage: "exclamationmark.circle")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Try Again") { Task { await downloadManager.retryDownload(download) } }
                            .buttonStyle(.bordered)
                    }
                    .font(.callout)
                } else if [.downloading, .pending, .paused].contains(download.status) {
                    transferProgress
                }
            }
            .padding(22)
        }
    }

    private var artwork: some View {
        VideoThumbnailBanner(thumbnailURL: download.thumbnailURL)
            .frame(height: artworkHeight)
            .contentShape(.rect)
    }

    private var transferProgress: some View {
        VStack(spacing: 12) {
            HStack {
                Text(download.status == .pending ? "Preparing video…" : download.status == .paused ? "Paused" : "Downloading")
                Spacer(minLength: 8)
                Text(download.progressPercentage)
                    .foregroundStyle(.secondary)
            }
            .font(.callout.monospacedDigit())

            ProgressView(value: download.progress)
                .progressViewStyle(.linear)
                .tint(download.status.tint)
                .animation(reduceMotion ? nil : .smooth(duration: 0.35), value: download.progress)
                .accessibilityLabel("Video download progress")

            HStack {
                Text(byteCount(download.downloadedSize))
                if let size = download.fileSize, size > 0 {
                    Text("of \(byteCount(size))")
                }
                Spacer(minLength: 0)
                if let speed = download.downloadSpeed, speed > 0 {
                    Text(download.formattedSpeed)
                }
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
    }

    private func byteCount(_ bytes: Int64) -> String {
        bytes == 0 ? "0 B" : ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

private struct VideoPlayControl: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Image(systemName: "play.fill")
            .font(.system(size: 23, weight: .medium))
            .foregroundStyle(.white)
            .offset(x: 2)
            .frame(width: 68, height: 68)
            .modifier(PlayControlSurface(opaque: reduceTransparency || contrast == .increased))
            .shadow(color: .black.opacity(0.28), radius: 18, y: 4)
            .accessibilityHidden(true)
    }
}

private struct PlayControlSurface: ViewModifier {
    let opaque: Bool

    func body(content: Content) -> some View {
        if opaque {
            content
                .background(Circle().fill(.black))
                .overlay { Circle().strokeBorder(.white.opacity(0.6), lineWidth: 1) }
        } else {
            content
                .universalGlassEffect(.clear.tint(.black.opacity(0.18)).interactive(), in: Circle())
        }
    }
}

private struct VideoPreviewButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay { Color.black.opacity(configuration.isPressed ? 0.12 : 0).allowsHitTesting(false) }
    }
}
