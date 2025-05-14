import Foundation
import AnyCodable

internal struct Aria2Body: Encodable {
    let id: String = UUID().uuidString
    let jsonrpc = "2.0"
    let method: String
    let params: [AnyEncodable]
}
