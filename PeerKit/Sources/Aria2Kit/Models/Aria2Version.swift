import Foundation

/// Typed response for aria2 getVersion
public struct Aria2VersionResponse: Decodable, Sendable {
    public let version: String
    public let enabledFeatures: [String]
}
