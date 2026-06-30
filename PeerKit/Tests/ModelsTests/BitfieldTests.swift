import Foundation
import Testing
@testable import Models

@Suite("Bitfield Tests")
struct BitfieldTests {
    @Test("Decodes pieces MSB-first")
    func decodePieces() {
        // 0xF0 => 1111 0000
        #expect(Bitfield.pieces(hex: "f0", count: 8) == [true, true, true, true, false, false, false, false])
        // 0xA => 1010
        #expect(Bitfield.pieces(hex: "a", count: 4) == [true, false, true, false])
    }

    @Test("Decodes uppercase hex")
    func decodeUppercase() {
        #expect(Bitfield.pieces(hex: "FF", count: 8) == Array(repeating: true, count: 8))
    }

    @Test("Completion is per-piece when count fits maxCells")
    func completionExact() {
        let cells = Bitfield.completion(hex: "f0", count: 8, maxCells: 64)
        #expect(cells == [1, 1, 1, 1, 0, 0, 0, 0])
    }

    @Test("Completion buckets aggregate ranges when over maxCells")
    func completionBucketed() {
        // 16 pieces, first 8 set, bucketed into 2 cells => [1.0, 0.0]
        let cells = Bitfield.completion(hex: "ff00", count: 16, maxCells: 2)
        #expect(cells == [1.0, 0.0])
    }

    @Test("Completion with nil hex is all zero")
    func completionNil() {
        let cells = Bitfield.completion(hex: nil, count: 4, maxCells: 4)
        #expect(cells == [0, 0, 0, 0])
    }

    @Test("Fraction set counts bits over piece count")
    func fractionSet() {
        #expect(Bitfield.fractionSet(hex: "f0", count: 8) == 0.5)
        #expect(Bitfield.fractionSet(hex: "ff", count: 8) == 1.0)
        #expect(Bitfield.fractionSet(hex: nil, count: 8) == 0)
        #expect(Bitfield.fractionSet(hex: "ff", count: 0) == 0)
    }

    @Test("Zero piece count returns empty")
    func zeroCount() {
        #expect(Bitfield.pieces(hex: "ff", count: 0).isEmpty)
        #expect(Bitfield.completion(hex: "ff", count: 0, maxCells: 8).isEmpty)
    }
}
