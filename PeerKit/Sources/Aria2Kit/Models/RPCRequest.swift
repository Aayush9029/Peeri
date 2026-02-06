import Foundation

/// A type-erased JSON value for building RPC params
public enum AnyJSON: Encodable, Sendable {
    case string(String)
    case int(Int)
    case int64(Int64)
    case double(Double)
    case bool(Bool)
    case array([AnyJSON])
    case dictionary([String: AnyJSON])
    case null

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .int64(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        case .array(let v): try container.encode(v)
        case .dictionary(let v): try container.encode(v)
        case .null: try container.encodeNil()
        }
    }
}

/// JSON-RPC 2.0 request body
struct RPCRequest: Encodable {
    let id: String
    let jsonrpc: String = "2.0"
    let method: String
    let params: [AnyJSON]

    init(method: Aria2Method, params: [AnyJSON], token: String?) {
        self.id = UUID().uuidString
        self.method = method.rawValue
        if let token = token {
            self.params = [.string("token:\(token)")] + params
        } else {
            self.params = params
        }
    }
}
