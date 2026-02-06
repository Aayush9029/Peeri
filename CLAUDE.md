# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is Peeri

Peeri is a native macOS torrent/download client (SwiftUI, macOS 13.3+) that wraps the [aria2](https://aria2.github.io/) download daemon. The app bundles an `aria2c` binary, launches it as a child process on startup, and communicates with it over its JSON-RPC HTTP API (localhost:6800, token `peeri`).

## Build & Run

Open `Peeri.xcodeproj` in Xcode. The project has a single target (`Peeri`) that links all PeerKit modules as local SPM packages. Build with **Cmd+B** or from CLI:

```bash
xcodebuild -project Peeri.xcodeproj -scheme Peeri -configuration Debug build
```

There are no tests, no linter, and no CI configured.

## Architecture

### Two-layer structure

1. **`Peeri/`** — the macOS app target (SwiftUI). Contains the `@main` app entry point, views, and the `DownloadManager` service.
2. **`PeerKit/`** — a local Swift package containing modular libraries that the app depends on.

### PeerKit modules (in `PeerKit/Sources/`)

| Module | Purpose | Key dependencies |
|---|---|---|
| **Aria2Kit** | JSON-RPC client for aria2 daemon. Uses `@DependencyClient` pattern (Point-Free). Wraps Alamofire HTTP calls in an actor (`Aria2ClientActor`) for thread safety. | Alamofire, AnyCodable, swift-dependencies |
| **Models** | `DownloadFile` and `DownloadStatus` — the core data model shared across the app. | KeyboardShortcuts |
| **Shared** | Re-exports Point-Free dependencies (Dependencies, Sharing, IdentifiedCollections). | swift-dependencies, swift-sharing, swift-identified-collections |
| **Assets** | Color/image constants for theming. | — |
| **UI** | Re-exports Assets. | Assets, Models, KeyboardShortcuts |

### Data flow

- `PeeriApp` launches the bundled `aria2c` binary, writes config to `~/.peeri/aria2/aria2.conf`, and auto-restarts the daemon on unexpected termination.
- `DownloadManager` (ObservableObject, `@MainActor`) polls aria2 every 1 second via `Aria2Client` to sync download state. It also persists download metadata as JSON files under `~/Documents/peeri/downloads/metadata/`.
- `Aria2Client` is injected via `@Dependency(\.aria2Client)` (Point-Free Dependencies pattern). The live implementation uses an internal actor that makes Alamofire JSON-RPC POST requests to `http://localhost:6800/jsonrpc`.
- Views read from `DownloadManager` via `@EnvironmentObject`.

### aria2 integration

- The `aria2c` Mach-O binary sits at the repo root (`./aria2c`) and is bundled as a resource.
- Config lives at `~/.peeri/aria2/aria2.conf`, logs at `~/.peeri/logs/aria2c.log`.
- RPC endpoint: `http://localhost:6800/jsonrpc`, secret token: `peeri`.
- `Aria2Method` enum in `PeerKit/Sources/Aria2Client/Aria2Method.swift` maps all aria2 JSON-RPC methods.

### Dependency injection

All service clients follow the Point-Free `@DependencyClient` / `DependencyKey` pattern with a `liveValue` static property. To add a new client: define the struct with closure properties, conform to `DependencyKey`, provide `liveValue`, and register on `DependencyValues`.

## Periphery / Dead Code

When running Periphery, **skip Aria2Kit warnings**. Many Aria2Kit types and properties are decoded from aria2's JSON-RPC but not yet consumed by the app — they map the full aria2 API surface and will be used as features are built out.
