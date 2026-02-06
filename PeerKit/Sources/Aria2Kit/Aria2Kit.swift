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

        return client
    }
}
