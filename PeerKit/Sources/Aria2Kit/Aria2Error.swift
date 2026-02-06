import Foundation

/// Typed errors for Aria2Kit operations
public enum Aria2Error: Error, LocalizedError {
    case notInitialized
    case invalidURL
    case rpcError(code: Int, message: String)
    case decodingError(String)
    case httpError(statusCode: Int)
    case connectionFailed(underlying: Error)
    case timeout
    case resourceNotFound
    case downloadTooSlow
    case networkError
    case notEnoughDiskSpace
    case fileAlreadyExists
    case fileIOError
    case dnsResolutionFailed
    case httpAuthFailed
    case torrentCorrupted
    case badMagnetURI
    case checksumFailed

    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Aria2 client not initialized"
        case .invalidURL:
            return "Invalid RPC endpoint URL"
        case .rpcError(let code, let message):
            return "Aria2 RPC error (\(code)): \(message)"
        case .decodingError(let detail):
            return "Failed to decode response: \(detail)"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .connectionFailed(let underlying):
            return "Connection failed: \(underlying.localizedDescription)"
        case .timeout:
            return "Operation timed out"
        case .resourceNotFound:
            return "Resource not found"
        case .downloadTooSlow:
            return "Download too slow"
        case .networkError:
            return "Network error"
        case .notEnoughDiskSpace:
            return "Not enough disk space"
        case .fileAlreadyExists:
            return "File already exists"
        case .fileIOError:
            return "File I/O error"
        case .dnsResolutionFailed:
            return "DNS resolution failed"
        case .httpAuthFailed:
            return "HTTP authorization failed"
        case .torrentCorrupted:
            return "Torrent file is corrupted"
        case .badMagnetURI:
            return "Bad magnet URI"
        case .checksumFailed:
            return "Checksum verification failed"
        }
    }

    /// Maps an aria2 error code string to a typed error, or nil for success.
    public static func fromAria2Code(_ code: String) -> Aria2Error? {
        switch code {
        case "0": return nil // success
        case "2": return .timeout
        case "3": return .resourceNotFound
        case "5": return .downloadTooSlow
        case "6": return .networkError
        case "9": return .notEnoughDiskSpace
        case "13": return .fileAlreadyExists
        case "17": return .fileIOError
        case "19": return .dnsResolutionFailed
        case "24": return .httpAuthFailed
        case "26": return .torrentCorrupted
        case "27": return .badMagnetURI
        case "32": return .checksumFailed
        default: return .rpcError(code: Int(code) ?? -1, message: "aria2 error code \(code)")
        }
    }
}
