import Foundation
import os.log
@_exported import Models

/// Actor-based JSON-RPC client using URLSession for thread-safe aria2 communication
actor Aria2RPCClient {
    private var baseURL: URL?
    private var token: String?
    private let session: URLSession
    private let logger = Logger(subsystem: "com.lovedoingthings.peeri", category: "Aria2RPCClient")

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    func initialize(ssl: Bool, host: String, port: UInt16, token: String?) {
        let scheme = ssl ? "https" : "http"
        self.baseURL = URL(string: "\(scheme)://\(host):\(port)/jsonrpc")
        self.token = token
        logger.info("Aria2 RPC client initialized: \(scheme)://\(host):\(port)/jsonrpc")
    }

    // MARK: - Generic RPC Call

    func call<T: Decodable>(_ method: Aria2Method, params: [AnyJSON] = []) async throws -> T {
        guard let url = baseURL else { throw Aria2Error.notInitialized }

        let request = RPCRequest(method: method, params: params, token: token)
        let bodyData = try JSONEncoder().encode(request)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = bodyData
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw Aria2Error.connectionFailed(underlying: error)
        }

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw Aria2Error.httpError(statusCode: httpResponse.statusCode)
        }

        let rpcResponse: RPCResponse<T>
        do {
            rpcResponse = try JSONDecoder().decode(RPCResponse<T>.self, from: data)
        } catch {
            throw Aria2Error.decodingError(error.localizedDescription)
        }

        if let rpcError = rpcResponse.error {
            throw Aria2Error.rpcError(code: rpcError.code, message: rpcError.message)
        }

        guard let result = rpcResponse.result else {
            throw Aria2Error.decodingError("Response had no result and no error")
        }

        return result
    }

    // MARK: - High-level Methods

    func addUri(_ uris: [String], options: [String: String]? = nil) async throws -> String {
        var params: [AnyJSON] = [.array(uris.map { .string($0) })]
        if let options = options {
            let dict = Dictionary(uniqueKeysWithValues: options.map { ($0.key, AnyJSON.string($0.value)) })
            params.append(.dictionary(dict))
        }
        return try await call(.addUri, params: params)
    }

    func addTorrent(_ torrentBase64: String, uris: [String] = [], options: [String: String]? = nil) async throws -> String {
        var params: [AnyJSON] = [.string(torrentBase64), .array(uris.map { .string($0) })]
        if let options = options {
            let dict = Dictionary(uniqueKeysWithValues: options.map { ($0.key, AnyJSON.string($0.value)) })
            params.append(.dictionary(dict))
        }
        return try await call(.addTorrent, params: params)
    }

    func tellStatus(gid: String) async throws -> Aria2StatusResponse {
        return try await call(.tellStatus, params: [.string(gid)])
    }

    func tellActive() async throws -> [Aria2StatusResponse] {
        return try await call(.tellActive)
    }

    func tellWaiting(offset: Int, num: Int) async throws -> [Aria2StatusResponse] {
        return try await call(.tellWaiting, params: [.int(offset), .int(num)])
    }

    func tellStopped(offset: Int, num: Int) async throws -> [Aria2StatusResponse] {
        return try await call(.tellStopped, params: [.int(offset), .int(num)])
    }

    func pause(gid: String) async throws -> String {
        return try await call(.pause, params: [.string(gid)])
    }

    func unpause(gid: String) async throws -> String {
        return try await call(.unpause, params: [.string(gid)])
    }

    func remove(gid: String) async throws -> String {
        return try await call(.remove, params: [.string(gid)])
    }

    func getVersion() async throws -> Aria2VersionResponse {
        return try await call(.getVersion)
    }

    func getGlobalStat() async throws -> Aria2GlobalStatResponse {
        return try await call(.getGlobalStat)
    }

    // MARK: - Force Variants

    func forceRemove(gid: String) async throws -> String {
        return try await call(.forceRemove, params: [.string(gid)])
    }

    func forcePause(gid: String) async throws -> String {
        return try await call(.forcePause, params: [.string(gid)])
    }

    func forcePauseAll() async throws -> String {
        return try await call(.forcePauseAll)
    }

    // MARK: - Batch Operations

    func pauseAll() async throws -> String {
        return try await call(.pauseAll)
    }

    func unpauseAll() async throws -> String {
        return try await call(.unpauseAll)
    }

    // MARK: - Query Methods

    func getPeers(gid: String) async throws -> [Aria2PeerInfo] {
        return try await call(.getPeers, params: [.string(gid)])
    }

    func getServers(gid: String) async throws -> [Aria2ServerGroup] {
        return try await call(.getServers, params: [.string(gid)])
    }

    func getFiles(gid: String) async throws -> [Aria2FileInfo] {
        return try await call(.getFiles, params: [.string(gid)])
    }

    func getUris(gid: String) async throws -> [Aria2UriInfo] {
        return try await call(.getUris, params: [.string(gid)])
    }

    // MARK: - Options

    func getOption(gid: String) async throws -> [String: String] {
        return try await call(.getOption, params: [.string(gid)])
    }

    func changeOption(gid: String, options: [String: String]) async throws -> String {
        let optionsJSON = AnyJSON.dictionary(options.mapValues { AnyJSON.string($0) })
        return try await call(.changeOption, params: [.string(gid), optionsJSON])
    }

    func getGlobalOption() async throws -> [String: String] {
        return try await call(.getGlobalOption)
    }

    func changeGlobalOption(options: [String: String]) async throws -> String {
        let optionsJSON = AnyJSON.dictionary(options.mapValues { AnyJSON.string($0) })
        return try await call(.changeGlobalOption, params: [optionsJSON])
    }

    // MARK: - Queue Management

    func changePosition(gid: String, pos: Int, how: String) async throws -> Int {
        return try await call(.changePosition, params: [.string(gid), .int(pos), .string(how)])
    }

    // MARK: - Metalink

    func addMetalink(metalink: String, options: [String: String]? = nil) async throws -> [String] {
        var params: [AnyJSON] = [.string(metalink)]
        if let options {
            params.append(.dictionary(options.mapValues { AnyJSON.string($0) }))
        }
        return try await call(.addMetalink, params: params)
    }

    // MARK: - Session & Cleanup

    func purgeDownloadResult() async throws -> String {
        return try await call(.purgeDownloadResult)
    }

    func removeDownloadResult(gid: String) async throws -> String {
        return try await call(.removeDownloadResult, params: [.string(gid)])
    }

    func getSessionInfo() async throws -> Aria2SessionInfoResponse {
        return try await call(.getSessionInfo)
    }

    func saveSession() async throws -> String {
        return try await call(.saveSession)
    }

    func shutdown() async throws -> String {
        return try await call(.shutdown)
    }

    func forceShutdown() async throws -> String {
        return try await call(.forceShutdown)
    }

    // MARK: - System Methods

    func listMethods() async throws -> [String] {
        return try await call(.systemListMethods)
    }

    func listNotifications() async throws -> [String] {
        return try await call(.systemListNotifications)
    }

    // MARK: - Download Processing

    func processStatus(_ status: Aria2StatusResponse) -> DownloadFile {
        let gid = status.gid

        // Extract URI
        var uri: URL
        if let files = status.files, let firstFile = files.first,
           let uris = firstFile.uris, let firstUri = uris.first,
           let validUri = URL(string: firstUri.uri) {
            uri = validUri
        } else if let infoHash = status.infoHash,
                  let magnetUri = URL(string: "magnet:?xt=urn:btih:" + infoHash) {
            uri = magnetUri
        } else {
            uri = URL(string: "file://localhost/unknown")!
        }

        // Extract file name
        var fileName = "download"
        var filePath: String? = nil
        if let files = status.files, let firstFile = files.first {
            let path = firstFile.path
            filePath = path.isEmpty ? nil : path
            let pathObject = path as NSString
            let extractedName = pathObject.lastPathComponent
            if !extractedName.isEmpty && extractedName != "/" {
                fileName = extractedName
            } else if !uri.lastPathComponent.isEmpty && uri.lastPathComponent != "/" {
                fileName = uri.lastPathComponent
            }
        } else if !uri.lastPathComponent.isEmpty && uri.lastPathComponent != "/" {
            fileName = uri.lastPathComponent
        }

        let totalLength = Int64(status.totalLength) ?? 0
        let completedLength = Int64(status.completedLength) ?? 0
        let downloadSpeed = Int64(status.downloadSpeed)
        let uploadSpeed = Int64(status.uploadSpeed)

        let downloadStatus: DownloadStatus
        switch status.status {
        case "active": downloadStatus = .downloading
        case "waiting": downloadStatus = .pending
        case "paused": downloadStatus = .paused
        case "complete":
            if status.bittorrent != nil && status.seeder == "true" {
                downloadStatus = .seeding
            } else {
                downloadStatus = .completed
            }
        case "removed": downloadStatus = .removed
        case "error": downloadStatus = .failed
        default: downloadStatus = .pending
        }

        let connections = status.connections.flatMap { Int($0) }
        let numSeeders = status.numSeeders.flatMap { Int($0) }
        let uploadedSize = status.uploadLength.flatMap { Int64($0) }

        return DownloadFile(
            id: .deterministic(from: gid),
            gid: gid,
            url: uri,
            fileName: fileName,
            filePath: filePath,
            fileSize: totalLength > 0 ? totalLength : nil,
            downloadedSize: completedLength,
            downloadSpeed: downloadSpeed,
            uploadSpeed: uploadSpeed,
            connections: connections,
            numSeeders: numSeeders,
            uploadedSize: uploadedSize,
            status: downloadStatus
        )
    }

    func processStatusList(_ statuses: [Aria2StatusResponse]) -> [DownloadFile] {
        return statuses.map { processStatus($0) }
    }
}
