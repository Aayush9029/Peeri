import Foundation

/// Typed response for aria2 getGlobalStat
public struct Aria2GlobalStatResponse: Decodable, Sendable {
    public let downloadSpeed: String
    public let uploadSpeed: String
    public let numActive: String
    public let numWaiting: String
    public let numStopped: String
    public let numStoppedTotal: String
}
