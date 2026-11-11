# Peeri

Peeri is a native macOS torrent and download client (SwiftUI, macOS 14+). It bundles the [aria2](https://aria2.github.io/) daemon, starts it as a child process, and controls it over JSON-RPC. It ships as the Homebrew cask `aayush9029/tap/peeri`. Status: early development, paused since February 2026.

## Commands

| Task | Command |
|------|---------|
| Build | `xcodebuild -project Peeri.xcodeproj -scheme Peeri -configuration Debug build` |
| Test PeerKit | `cd PeerKit && swift test` |
| Find unused code | `periphery scan` |

The repository has no linter and no build CI. `.github/workflows/claude.yml` only runs the Claude GitHub action on issues and pull requests.

## Architecture

| Part | Path | Role |
|------|------|------|
| App target | `Peeri/` | `PeeriApp`, views, `Services/` |
| `Aria2DaemonManager` | `Peeri/Services/` | Starts the bundled `aria2c`, writes its config, restarts it when it stops |
| `DownloadManager` | `Peeri/Services/` | `@Observable` model. It polls aria2 every second. Views read it with `@Environment(DownloadManager.self)`. |
| PeerKit | `PeerKit/` | Local SPM package: `Aria2Kit`, `Models`, `Shared`, `Assets`, `UI` |

- `Aria2Kit` is a `@DependencyClient` (Point-Free Dependencies) over an actor (`Aria2RPCClient`) that posts JSON-RPC with `URLSession`. `Aria2Method` maps the aria2 RPC methods.
- `Models` holds `DownloadModel` and `PeeriSettings`. `PeeriSettings` generates the `aria2.conf` content.
- To add a service client, define a struct with closure properties, conform it to `DependencyKey` with a `liveValue`, and register it on `DependencyValues`.

## aria2

- The `aria2c` Mach-O binary is at the repository root. The Xcode project copies it into the app resources.
- The RPC port is `16800`. `PeeriSettings` holds the RPC secret. Change both `PeeriSettings` and `DownloadManager` together.
- The config is at `~/.peeri/aria2/aria2.conf`, and the log is at `~/.peeri/logs/aria2c.log`.
- `SETUP.md` describes an old `start_aria2.sh` flow. The app does not use that script now.

## Rules

- When you run Periphery, ignore the warnings for `Aria2Kit`. Its types map the full aria2 API, and the app does not use all of them yet.
