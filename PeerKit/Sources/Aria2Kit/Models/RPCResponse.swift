import Foundation

/// JSON-RPC 2.0 response wrapper
struct RPCResponse<T: Decodable>: Decodable {
    let id: String
    let jsonrpc: String
    let result: T?
    let error: RPCError?
}

/// JSON-RPC 2.0 error object
struct RPCError: Decodable {
    let code: Int
    let message: String
}
