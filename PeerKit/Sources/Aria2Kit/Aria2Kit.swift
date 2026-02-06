import Dependencies
import DependenciesMacros
import Foundation
import os.log
@_exported import Models

// MARK: - Public Client Interface

@DependencyClient
public struct Aria2Client: Sendable, DependencyKey {
    public var initialize: @Sendable (Bool, String, UInt16, String?) -> Void = { _, _, _, _ in }
    public var addDownload: @Sendable (URL, [String: String]?) async throws -> String = { _, _ in "" }
    public var addTorrent: @Sendable (String, [String], [String: String]?) async throws -> String = { _, _, _ in "" }
    public var tellStatus: @Sendable (String) async throws -> DownloadFile = { _ in
        DownloadFile(gid: "", url: URL(string: "about:blank")!, fileName: "")
    }
    public var tellActive: @Sendable () async throws -> [DownloadFile] = { [] }
    public var tellWaiting: @Sendable (Int, Int) async throws -> [DownloadFile] = { _, _ in [] }
    public var tellStopped: @Sendable (Int, Int) async throws -> [DownloadFile] = { _, _ in [] }
    public var pause: @Sendable (String) async throws -> Bool = { _ in false }
    public var unpause: @Sendable (String) async throws -> Bool = { _ in false }
    public var remove: @Sendable (String) async throws -> Bool = { _ in false }
    public var getVersion: @Sendable () async throws -> String = { "" }
    public var getGlobalStat: @Sendable () async throws -> Aria2GlobalStatResponse = {
        Aria2GlobalStatResponse(downloadSpeed: "0", uploadSpeed: "0", numActive: "0", numWaiting: "0", numStopped: "0", numStoppedTotal: "0")
    }

    // Force variants
    public var forceRemove: @Sendable (String) async throws -> Bool = { _ in false }
    public var forcePause: @Sendable (String) async throws -> Bool = { _ in false }
    public var forcePauseAll: @Sendable () async throws -> Void = {}

    // Batch operations
    public var pauseAll: @Sendable () async throws -> Void = {}
    public var unpauseAll: @Sendable () async throws -> Void = {}

    // Query methods
    public var getPeers: @Sendable (String) async throws -> [Aria2PeerInfo] = { _ in [] }
    public var getServers: @Sendable (String) async throws -> [Aria2ServerGroup] = { _ in [] }
    public var getFiles: @Sendable (String) async throws -> [Aria2FileInfo] = { _ in [] }
    public var getUris: @Sendable (String) async throws -> [Aria2UriInfo] = { _ in [] }

    // Options
    public var getOption: @Sendable (String) async throws -> [String: String] = { _ in [:] }
    public var changeOption: @Sendable (String, [String: String]) async throws -> Void = { _, _ in }
    public var getGlobalOption: @Sendable () async throws -> [String: String] = { [:] }
    public var changeGlobalOption: @Sendable ([String: String]) async throws -> Void = { _ in }

    // Queue management
    public var changePosition: @Sendable (String, Int, String) async throws -> Int = { _, _, _ in 0 }

    // Metalink
    public var addMetalink: @Sendable (String, [String: String]?) async throws -> [String] = { _, _ in [] }

    // Session & cleanup
    public var purgeDownloadResult: @Sendable () async throws -> Void = {}
    public var removeDownloadResult: @Sendable (String) async throws -> Void = { _ in }
    public var getSessionInfo: @Sendable () async throws -> String = { "" }
    public var saveSession: @Sendable () async throws -> Void = {}
    public var shutdown: @Sendable () async throws -> Void = {}
    public var forceShutdown: @Sendable () async throws -> Void = {}
}

// MARK: - Dependency Registration

public extension DependencyValues {
    var aria2Client: Aria2Client {
        get { self[Aria2Client.self] }
        set { self[Aria2Client.self] = newValue }
    }
}

// MARK: - Live Implementation

public extension Aria2Client {
    static var liveValue: Self {
        let rpcClient = Aria2RPCClient()

        var client = Self()
        client.initialize = { ssl, host, port, token in
            Task {
                await rpcClient.initialize(ssl: ssl, host: host, port: port, token: token)
            }
        }
        client.addDownload = { url, options in
            try await rpcClient.addUri([url.absoluteString], options: options)
        }
        client.addTorrent = { base64, uris, options in
            try await rpcClient.addTorrent(base64, uris: uris, options: options)
        }
        client.tellStatus = { gid in
            let status = try await rpcClient.tellStatus(gid: gid)
            return await rpcClient.processStatus(status)
        }
        client.tellActive = {
            let statuses = try await rpcClient.tellActive()
            return await rpcClient.processStatusList(statuses)
        }
        client.tellWaiting = { offset, num in
            let statuses = try await rpcClient.tellWaiting(offset: offset, num: num)
            return await rpcClient.processStatusList(statuses)
        }
        client.tellStopped = { offset, num in
            let statuses = try await rpcClient.tellStopped(offset: offset, num: num)
            return await rpcClient.processStatusList(statuses)
        }
        client.pause = { gid in
            let result = try await rpcClient.pause(gid: gid)
            return !result.isEmpty
        }
        client.unpause = { gid in
            let result = try await rpcClient.unpause(gid: gid)
            return !result.isEmpty
        }
        client.remove = { gid in
            let result = try await rpcClient.remove(gid: gid)
            return !result.isEmpty
        }
        client.getVersion = {
            let response = try await rpcClient.getVersion()
            return response.version
        }
        client.getGlobalStat = {
            try await rpcClient.getGlobalStat()
        }

        // Force variants
        client.forceRemove = { gid in
            let result = try await rpcClient.forceRemove(gid: gid)
            return !result.isEmpty
        }
        client.forcePause = { gid in
            let result = try await rpcClient.forcePause(gid: gid)
            return !result.isEmpty
        }
        client.forcePauseAll = {
            _ = try await rpcClient.forcePauseAll()
        }

        // Batch operations
        client.pauseAll = {
            _ = try await rpcClient.pauseAll()
        }
        client.unpauseAll = {
            _ = try await rpcClient.unpauseAll()
        }

        // Query methods
        client.getPeers = { gid in
            try await rpcClient.getPeers(gid: gid)
        }
        client.getServers = { gid in
            try await rpcClient.getServers(gid: gid)
        }
        client.getFiles = { gid in
            try await rpcClient.getFiles(gid: gid)
        }
        client.getUris = { gid in
            try await rpcClient.getUris(gid: gid)
        }

        // Options
        client.getOption = { gid in
            try await rpcClient.getOption(gid: gid)
        }
        client.changeOption = { gid, options in
            _ = try await rpcClient.changeOption(gid: gid, options: options)
        }
        client.getGlobalOption = {
            try await rpcClient.getGlobalOption()
        }
        client.changeGlobalOption = { options in
            _ = try await rpcClient.changeGlobalOption(options: options)
        }

        // Queue management
        client.changePosition = { gid, pos, how in
            try await rpcClient.changePosition(gid: gid, pos: pos, how: how)
        }

        // Metalink
        client.addMetalink = { metalink, options in
            try await rpcClient.addMetalink(metalink: metalink, options: options)
        }

        // Session & cleanup
        client.purgeDownloadResult = {
            _ = try await rpcClient.purgeDownloadResult()
        }
        client.removeDownloadResult = { gid in
            _ = try await rpcClient.removeDownloadResult(gid: gid)
        }
        client.getSessionInfo = {
            let response = try await rpcClient.getSessionInfo()
            return response.sessionId
        }
        client.saveSession = {
            _ = try await rpcClient.saveSession()
        }
        client.shutdown = {
            _ = try await rpcClient.shutdown()
        }
        client.forceShutdown = {
            _ = try await rpcClient.forceShutdown()
        }

        return client
    }
}
