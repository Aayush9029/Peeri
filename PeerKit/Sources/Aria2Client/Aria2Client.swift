import Dependencies
import DependenciesMacros
import Foundation
import Alamofire
import AnyCodable
import os.log
@_exported import Models

@DependencyClient
public struct Aria2Client: Sendable, DependencyKey {
    public var initialize: @Sendable (Bool, String, UInt16, String?) -> Void = { _, _, _, _ in }
    public var addDownload: @Sendable (URL, [String: String]?) async throws -> String = { _, _ in "" }
    public var tellStatus: @Sendable (String) async throws -> DownloadStatus = { _ in .pending }
    public var tellActive: @Sendable () async throws -> [DownloadFile] = { [] }
    public var tellWaiting: @Sendable (Int, Int) async throws -> [DownloadFile] = { _, _ in [] }
    public var tellStopped: @Sendable (Int, Int) async throws -> [DownloadFile] = { _, _ in [] }
    public var pause: @Sendable (String) async throws -> Bool = { _ in false }
    public var unpause: @Sendable (String) async throws -> Bool = { _ in false }
    public var remove: @Sendable (String) async throws -> Bool = { _ in false }
    public var getVersion: @Sendable () async throws -> String = { "" }
}

public extension DependencyValues {
    var aria2Client: Aria2Client {
        get { self[Aria2Client.self] }
        set { self[Aria2Client.self] = newValue }
    }
}

// This will be our implementation
private actor Aria2ClientActor {
    private var aria2: Aria2?
    private let logger = Logger(subsystem: "com.lovedoingthings.peeri", category: "Aria2Client")
    
    func initialize(ssl: Bool, host: String, port: UInt16, token: String?) {
        self.aria2 = Aria2(ssl: ssl, host: host, port: port, token: token)
        logger.info("Aria2 client initialized with host: \(host), port: \(port)")
    }
    
    func addDownload(url: URL, options: [String: String]?) async throws -> String {
        guard let aria2 = aria2 else {
            throw NSError(domain: "Aria2ClientError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Aria2 client not initialized"])
        }
        
        // Convert options to AnyCodable
        var optionsParam: [String: AnyCodable] = [:]
        if let options = options {
            for (key, value) in options {
                optionsParam[key] = AnyCodable(value)
            }
        }
        
        // Create request parameters
        let params: [AnyEncodable] = [
            AnyEncodable([url.absoluteString]),
            AnyEncodable(optionsParam)
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            aria2.call(method: .addUri, params: params)
                .responseDecodable(of: Aria2Response<String>.self) { response in
                    switch response.result {
                    case .success(let success):
                        continuation.resume(returning: success.result)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    func tellStatus(gid: String) async throws -> DownloadStatus {
        guard let aria2 = self.aria2 else {
            throw NSError(domain: "Aria2ClientError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Aria2 client not initialized"])
        }
        
        // Create request parameters
        let params: [AnyEncodable] = [AnyEncodable(gid)]
        
        return try await withCheckedThrowingContinuation { continuation in
            aria2.call(method: .tellStatus, params: params)
                .responseDecodable(of: Aria2Response<[String: AnyCodable]>.self) { response in
                    switch response.result {
                    case .success(let success):
                        // Extract status from response
                        if let statusValue = success.result["status"]?.value as? String {
                            let status: DownloadStatus
                            switch statusValue {
                            case "active":
                                status = .downloading
                            case "waiting":
                                status = .pending
                            case "paused":
                                status = .paused
                            case "complete":
                                status = .completed
                            case "error":
                                status = .failed
                            default:
                                status = .pending
                            }
                            continuation.resume(returning: status)
                        } else {
                            continuation.resume(returning: .pending)
                        }
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    func tellActive() async throws -> [DownloadFile] {
        guard let aria2 = self.aria2 else {
            throw NSError(domain: "Aria2ClientError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Aria2 client not initialized"])
        }
        
        // Empty params array for tellActive
        let params: [AnyEncodable] = []
        
        return try await withCheckedThrowingContinuation { continuation in
            aria2.call(method: .tellActive, params: params)
                .responseDecodable(of: Aria2Response<[[String: AnyCodable]]>.self) { response in
                    switch response.result {
                    case .success(let success):
                        let downloads = self.processDownloadList(success.result)
                        continuation.resume(returning: downloads)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    func tellWaiting(offset: Int, num: Int) async throws -> [DownloadFile] {
        guard let aria2 = self.aria2 else {
            throw NSError(domain: "Aria2ClientError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Aria2 client not initialized"])
        }
        
        // Params for tellWaiting
        let params: [AnyEncodable] = [
            AnyEncodable(offset),
            AnyEncodable(num)
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            aria2.call(method: .tellWaiting, params: params)
                .responseDecodable(of: Aria2Response<[[String: AnyCodable]]>.self) { response in
                    switch response.result {
                    case .success(let success):
                        let downloads = self.processDownloadList(success.result)
                        continuation.resume(returning: downloads)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    func tellStopped(offset: Int, num: Int) async throws -> [DownloadFile] {
        guard let aria2 = self.aria2 else {
            throw NSError(domain: "Aria2ClientError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Aria2 client not initialized"])
        }
        
        // Params for tellStopped
        let params: [AnyEncodable] = [
            AnyEncodable(offset),
            AnyEncodable(num)
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            aria2.call(method: .tellStopped, params: params)
                .responseDecodable(of: Aria2Response<[[String: AnyCodable]]>.self) { response in
                    switch response.result {
                    case .success(let success):
                        let downloads = self.processDownloadList(success.result)
                        continuation.resume(returning: downloads)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    // Helper method to process download list from aria2 response
    private func processDownloadList(_ items: [[String: AnyCodable]]) -> [DownloadFile] {
        return items.compactMap { item -> DownloadFile? in
            guard let gid = item["gid"]?.value as? String,
                  let filesArray = item["files"] as? [[String: AnyCodable]],
                  let firstFile = filesArray.first,
                  let urisArray = firstFile["uris"] as? [[String: AnyCodable]],
                  let firstUri = urisArray.first,
                  let uriString = firstUri["uri"]?.value as? String,
                  let uri = URL(string: uriString),
                  let path = firstFile["path"]?.value as? String else {
                return nil
            }
            
            // Extract file name from path
            let fileName = (path as NSString).lastPathComponent
            
            // Extract file size
            let totalLength = (item["totalLength"]?.value as? String).flatMap { Int64($0) } ?? 0
            let completedLength = (item["completedLength"]?.value as? String).flatMap { Int64($0) } ?? 0
            
            // Determine status
            let statusString = item["status"]?.value as? String ?? ""
            let status: DownloadStatus
            switch statusString {
            case "active":
                status = .downloading
            case "waiting":
                status = .pending
            case "paused":
                status = .paused
            case "complete":
                status = .completed
            case "error":
                status = .failed
            default:
                status = .pending
            }
            
            // Create download object
            return DownloadFile(
                id: UUID(uuidString: gid) ?? UUID(),
                url: uri,
                fileName: fileName,
                fileSize: totalLength > 0 ? totalLength : nil,
                downloadedSize: completedLength,
                status: status,
                completedAt: status == .completed ? Date() : nil
            )
        }
    }
    
    func pause(gid: String) async throws -> Bool {
        guard let aria2 = self.aria2 else {
            throw NSError(domain: "Aria2ClientError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Aria2 client not initialized"])
        }
        
        // Params for pause
        let params: [AnyEncodable] = [AnyEncodable(gid)]
        
        return try await withCheckedThrowingContinuation { continuation in
            aria2.call(method: .pause, params: params)
                .responseDecodable(of: Aria2Response<String>.self) { response in
                    switch response.result {
                    case .success(let success):
                        // If we get a result, it should be the GID, indicating success
                        continuation.resume(returning: !success.result.isEmpty)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    func unpause(gid: String) async throws -> Bool {
        guard let aria2 = self.aria2 else {
            throw NSError(domain: "Aria2ClientError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Aria2 client not initialized"])
        }
        
        // Params for unpause
        let params: [AnyEncodable] = [AnyEncodable(gid)]
        
        return try await withCheckedThrowingContinuation { continuation in
            aria2.call(method: .unpause, params: params)
                .responseDecodable(of: Aria2Response<String>.self) { response in
                    switch response.result {
                    case .success(let success):
                        // If we get a result, it should be the GID, indicating success
                        continuation.resume(returning: !success.result.isEmpty)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    func remove(gid: String) async throws -> Bool {
        guard let aria2 = self.aria2 else {
            throw NSError(domain: "Aria2ClientError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Aria2 client not initialized"])
        }
        
        // Params for remove
        let params: [AnyEncodable] = [AnyEncodable(gid)]
        
        return try await withCheckedThrowingContinuation { continuation in
            aria2.call(method: .remove, params: params)
                .responseDecodable(of: Aria2Response<String>.self) { response in
                    switch response.result {
                    case .success(let success):
                        // If we get a result, it should be the GID, indicating success
                        continuation.resume(returning: !success.result.isEmpty)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    func getVersion() async throws -> String {
        guard let aria2 = self.aria2 else {
            throw NSError(domain: "Aria2ClientError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Aria2 client not initialized"])
        }
        
        // Empty params for getVersion
        let params: [AnyEncodable] = []
        
        return try await withCheckedThrowingContinuation { continuation in
            aria2.call(method: .getVersion, params: params)
                .responseDecodable(of: Aria2Response<[String: AnyCodable]>.self) { response in
                    switch response.result {
                    case .success(let success):
                        if let version = success.result["version"]?.value as? String {
                            continuation.resume(returning: version)
                        } else {
                            continuation.resume(returning: "Unknown")
                        }
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
}

public extension Aria2Client {
    static var liveValue: Self {
        let actor = Aria2ClientActor()
        
        var client = Self()
        client.initialize = { ssl, host, port, token in
            Task {
                await actor.initialize(ssl: ssl, host: host, port: port, token: token)
            }
        }
        client.addDownload = { url, options in
            try await actor.addDownload(url: url, options: options)
        }
        client.tellStatus = { gid in
            try await actor.tellStatus(gid: gid)
        }
        client.tellActive = {
            try await actor.tellActive()
        }
        client.tellWaiting = { offset, num in
            try await actor.tellWaiting(offset: offset, num: num)
        }
        client.tellStopped = { offset, num in
            try await actor.tellStopped(offset: offset, num: num)
        }
        client.pause = { gid in
            try await actor.pause(gid: gid)
        }
        client.unpause = { gid in
            try await actor.unpause(gid: gid)
        }
        client.remove = { gid in
            try await actor.remove(gid: gid)
        }
        client.getVersion = {
            try await actor.getVersion()
        }
        
        return client
    }
}

// Response structure for Aria2 JSON-RPC
struct Aria2Response<T: Decodable>: Decodable {
    let id: String
    let jsonrpc: String
    let result: T
}