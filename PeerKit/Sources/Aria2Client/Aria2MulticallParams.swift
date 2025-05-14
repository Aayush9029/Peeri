import AnyCodable

public struct Aria2MulticallParams: Encodable {
    let methodName: Aria2Method
    let params: [AnyEncodable]
}
