import Testing

@testable import Snappy

@Suite("Snappy round-trip")
internal struct SnappyTests {
  // MARK: - Round-trip

  @Test(
    "round-trips representative payloads",
    arguments: [
      Payload(name: "empty", bytes: []),
      Payload(name: "single byte", bytes: [0x41]),
      Payload(name: "shorter than a copy", bytes: [0x41, 0x42, 0x43]),
      Payload(name: "highly repetitive", bytes: [UInt8](repeating: 0x41, count: 4_096)),
      Payload(name: "run of zeroes", bytes: [UInt8](repeating: 0x00, count: 70_000)),
      Payload(name: "structured", bytes: (0..<10_000).map { UInt8($0 % 251) }),
      Payload(name: "text-like", bytes: Payload.repeatingText(count: 8_192)),
      Payload(name: "incompressible", bytes: Payload.pseudoRandom(count: 10_000)),
    ]
  )
  internal func roundTrips(payload: Payload) throws {
    let compressed = Snappy.compress(payload.bytes)
    #expect(try Snappy.decompress(compressed) == payload.bytes)
  }

  @Test("round-trips every length across the tag-encoding boundaries")
  internal func roundTripsBoundaryLengths() throws {
    // Literal tags change encoding at 60/256/65536 bytes, so sweep those edges.
    let lengths = [0, 1, 59, 60, 61, 62, 63, 64, 255, 256, 257, 65_535, 65_536, 65_537]
    for length in lengths {
      let bytes = (0..<length).map { UInt8($0 % 251) }
      let restored = try Snappy.decompress(Snappy.compress(bytes))
      #expect(restored == bytes, "failed at length \(length)")
    }
  }

  @Test("compresses repetitive input well below its original size")
  internal func compressesRepetitiveInput() {
    let bytes = [UInt8](repeating: 0x5A, count: 65_536)
    let compressed = Snappy.compress(bytes)
    #expect(compressed.count < bytes.count / 10)
  }

  @Test("never exceeds the advertised worst case")
  internal func respectsMaximumCompressedLength() {
    for count in [0, 1, 60, 1_000, 10_000] {
      let bytes = Payload.pseudoRandom(count: count)
      let compressed = Snappy.compress(bytes)
      #expect(compressed.count <= Snappy.maximumCompressedLength(for: count))
    }
  }

  // MARK: - Preamble

  @Test("reports the uncompressed length without decoding the body")
  internal func readsUncompressedLength() throws {
    for count in [0, 1, 127, 128, 16_384] {
      let compressed = Snappy.compress(Payload.pseudoRandom(count: count))
      #expect(try Snappy.uncompressedLength(of: compressed) == count)
    }
  }
}
