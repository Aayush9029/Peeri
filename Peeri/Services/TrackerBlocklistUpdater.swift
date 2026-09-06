import Foundation
import Models
import Shared
import SwiftUI

@MainActor
@Observable
final class TrackerBlocklistUpdater {
    @ObservationIgnored @Shared(.settings) private var settings
    var isUpdating = false
    var error: String?

    func refreshIfNeeded() async {
        guard let lists = settings.advanced.trackerBlocklists, !lists.enabled.isEmpty,
              lists.updatedAt.map({ Date().timeIntervalSince($0) > 86_400 }) ?? true else { return }
        await update()
    }

    func runAutomaticUpdates() async {
        while !Task.isCancelled {
            await refreshIfNeeded()
            do { try await Task.sleep(for: .seconds(3600)) }
            catch { return }
        }
    }

    func update() async {
        guard !isUpdating else { return }
        isUpdating = true
        error = nil
        defer { isUpdating = false }
        do {
            var request = URLRequest(url: URL(string: "https://raw.githubusercontent.com/ngosang/trackerslist/master/blacklist.txt")!)
            request.timeoutInterval = 20
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  data.count < 2_000_000, let text = String(data: data, encoding: .utf8) else {
                throw URLError(.badServerResponse)
            }
            var updated = settings.advanced.trackerBlocklists ?? TrackerBlocklists()
            try updated.update(from: text)
            $settings.withLock {
                updated.enabled = $0.advanced.trackerBlocklists?.enabled ?? []
                $0.advanced.trackerBlocklists = updated
            }
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled else { return }
            self.error = "Couldn’t update the lists. Your previous exclusions are still in use."
        }
    }
}
