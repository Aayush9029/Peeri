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
        }
    }
}
