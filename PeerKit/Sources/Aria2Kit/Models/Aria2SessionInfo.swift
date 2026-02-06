import Foundation

/// Session information returned by `aria2.getSessionInfo`.
public struct Aria2SessionInfoResponse: Decodable, Sendable {
    /// Session ID, regenerated each time aria2 is invoked
    public let sessionId: String
}
