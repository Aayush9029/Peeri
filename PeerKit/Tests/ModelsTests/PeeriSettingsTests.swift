import Foundation
import Testing
@testable import Models

@Suite("PeeriSettings Tests")
struct PeeriSettingsTests {
    @Test("Decodes legacy min split size notation")
    func decodesLegacyMinSplitSizeNotation() throws {
        let data = try #require(#"{"minSplitSize":"512K"}"#.data(using: .utf8))
        let settings = try JSONDecoder().decode(PeeriSettings.self, from: data)

        #expect(settings.minSplitSize == 1)
    }

    @Test("Writes min split size as aria2 notation")
    func writesMinSplitSizeAsAria2Notation() {
        let settings = PeeriSettings(minSplitSize: 4)

        #expect(settings.toAria2GlobalOptions()["min-split-size"] == "4M")
    }
}
