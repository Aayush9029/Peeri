import Dependencies
import DependenciesMacros
import Foundation
import os.log

@DependencyClient
public struct AnalyticsClient: Sendable, DependencyKey {
    public var trackEvent: @Sendable (String) -> Void = { _ in }
    public var trackEventWithProperties: @Sendable (_ event: String, _ properties: [String: String]) -> Void = { _, _ in }
}

public extension DependencyValues {
    var analyticsClient: AnalyticsClient {
        get { self[AnalyticsClient.self] }
        set { self[AnalyticsClient.self] = newValue }
    }
}

public extension AnalyticsClient {
    static var liveValue: Self = .init(
        trackEvent: { event in
            trackWithProperties(event: event, properties: [:])
        },
        trackEventWithProperties: { event, properties in
            trackWithProperties(event: event, properties: properties)
        }
    )

    static func trackWithProperties(
        event: String,
        properties: [String: String]
    ) {
        os_log(
            "📊 Tracking event: %{public}@ with properties: %{public}@",
            event,
            properties.description
        )
        // Simplified analytics without Mixpanel dependency for now
    }
}