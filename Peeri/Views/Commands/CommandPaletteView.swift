import AppKit
import Models
import SwiftUI

struct CommandPaletteView: View {
    let commands: [PeeriCommand]
    let initialPage: CommandPanelPage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = CommandPanelPage.commands
    @State private var query = ""
    @State private var downloadModel = AddDownloadModel()
    @State private var clipboardLinks = DownloadLinks("")
    @State private var selection: String?
    @FocusState private var isFocused: Bool

    init(commands: [PeeriCommand], initialPage: CommandPanelPage) {
        self.commands = commands
        self.initialPage = initialPage
        _page = State(initialValue: initialPage)
    }

    private var matches: [PeeriCommand] {
        let links = query.isEmpty ? clipboardLinks : DownloadLinks(query)
        var result = commands.filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) }
        if links.isValid {
            result.insert(PeeriCommand(
                id: "addLinks", title: "Add to Downloads", subtitle: links.summary,
                symbol: "arrow.down.circle", shortcut: query.isEmpty ? "Clipboard" : "",
                downloadInput: links.urls.map(\.absoluteString).joined(separator: "\n"), action: {}
            ), at: 0)
        }
        return result
    }

    var body: some View {
        Group {
            switch page {
            case .commands:
                commandList
                    .transition(.opacity.combined(with: .offset(x: -12)))
            case .addDownload:
                AddDownloadView(goBack: showCommands, model: downloadModel)
                    .transition(.opacity.combined(with: .offset(x: 12)))
            }
        }
        .frame(width: 640)
        .background(.regularMaterial, in: .rect(cornerRadius: 20))
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.primary.opacity(0.12), lineWidth: 0.75)
                .allowsHitTesting(false)
        }
        .onAppear(perform: prepare)
        .onChange(of: initialPage) { _, newPage in show(newPage) }
        .animation(reduceMotion ? nil : .smooth(duration: 0.22), value: page)
    }

    private var commandList: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 19, weight: .light))
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                TextField("Search Peeri…", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18))
                    .focused($isFocused)
                    .onSubmit(runSelection)
                    .accessibilityLabel("Search commands or paste a link")
            }
            .padding(.horizontal, 20)
            .frame(height: 72)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        Text(query.isEmpty ? "Commands" : "Results")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 5)
                        ForEach(matches) { command in
                            Button { run(command) } label: {
                                CommandPanelRow(title: command.title, subtitle: command.subtitle, symbol: command.symbol, shortcut: command.shortcut, selected: selection == command.id)
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(selection == command.id ? .isSelected : [])
                            .id(command.id)
                        }
                        if matches.isEmpty {
                            Text("No matching commands")
                                .foregroundStyle(.secondary)
                                .padding(10)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 12)
                }
                .onChange(of: selection) { _, value in
                    if let value { proxy.scrollTo(value) }
                }
            }
            .frame(height: 304)

            CommandPanelFooter {
                CommandPanelAction(title: "Close", key: "esc") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                CommandPanelAction(title: selectedOpensForm ? "Open" : "Run Command", key: "↵", action: runSelection)
                    .keyboardShortcut(.defaultAction)
                    .disabled(matches.isEmpty)
            }
        }
        .onChange(of: query) { _, _ in selection = matches.first?.id }
        .onKeyPress(.downArrow) { move(1); return .handled }
        .onKeyPress(.upArrow) { move(-1); return .handled }
    }

    private var selectedOpensForm: Bool {
        (matches.first { $0.id == selection } ?? matches.first)?.downloadInput != nil
    }

    private func prepare() {
        clipboardLinks = DownloadLinks(NSPasteboard.general.string(forType: .string) ?? "")
        show(initialPage)
        selection = matches.first?.id
    }

    private func show(_ page: CommandPanelPage) {
        if page == .addDownload, clipboardLinks.isValid {
            downloadModel.urlText = clipboardLinks.urls.map(\.absoluteString).joined(separator: "\n")
        }
        self.page = page
        isFocused = page == .commands
    }

    private func showCommands() {
        page = .commands
        isFocused = true
    }

    private func move(_ offset: Int) {
        guard !matches.isEmpty else { return }
        let index = matches.firstIndex { $0.id == selection } ?? 0
        selection = matches[(index + offset + matches.count) % matches.count].id
    }

    private func runSelection() {
        guard let command = matches.first(where: { $0.id == selection }) ?? matches.first else { return }
        run(command)
    }

    private func run(_ command: PeeriCommand) {
        if let input = command.downloadInput {
            if !input.isEmpty {
                downloadModel.urlText = input
            } else if downloadModel.isEmpty && clipboardLinks.isValid {
                downloadModel.urlText = clipboardLinks.urls.map(\.absoluteString).joined(separator: "\n")
            }
            page = .addDownload
        } else {
            dismiss()
            command.action()
        }
    }
}
