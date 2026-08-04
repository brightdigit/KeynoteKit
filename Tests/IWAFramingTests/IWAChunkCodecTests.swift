import IWAFraming
import Snappy
import Testing

/// Apple chunk framing over the Snappy block codec.
///
/// The layout under test is the one measured in
/// `research/findings/snappy_survey.md` §1: a `0x00` type byte, a 3-byte
/// little-endian compressed length, then a stock Snappy block, with chunks
/// split at exactly 64 KiB of uncompressed payload.
@Suite("IWAChunkCodec")
internal struct IWAChunkCodecTests {
  // MARK: - Round-trips

  @Test("round-trips an empty payload as empty framing")
  internal func roundTripsEmptyPayload() throws {
    let framed = IWAChunkCodec.default.encode([])
    #expect(framed.isEmpty)
    #expect(try IWAChunkCodec.default.decode(framed).isEmpty)
  }

  @Test("round-trips a small payload in a single chunk")
  internal func roundTripsSmallPayload() throws {
    let payload = Array("the quick brown fox jumps over the lazy dog".utf8)
    let framed = IWAChunkCodec.default.encode(payload)
    #expect(framed[0] == 0x00)
    #expect(chunkSizes(of: framed).count == 1)
    #expect(try IWAChunkCodec.default.decode(framed) == payload)
  }

  @Test("round-trips a multi-chunk payload")
  internal func roundTripsMultiChunkPayload() throws {
    let payload = pseudoRandom(count: 200_000)
    let framed = IWAChunkCodec.default.encode(payload)
    #expect(try IWAChunkCodec.default.decode(framed) == payload)
  }

  // MARK: - Chunk splitting

  @Test("keeps a payload of exactly 64 KiB in one chunk")
  internal func keepsBoundaryPayloadInOneChunk() throws {
    let payload = pseudoRandom(count: 65_536)
    let framed = IWAChunkCodec.default.encode(payload)
    #expect(chunkSizes(of: framed).count == 1)
    #expect(try IWAChunkCodec.default.decode(framed) == payload)
  }

  @Test("splits one byte past 64 KiB into two chunks")
  internal func splitsPastBoundaryIntoTwoChunks() throws {
    let payload = pseudoRandom(count: 65_537)
    let framed = IWAChunkCodec.default.encode(payload)
    let sizes = chunkSizes(of: framed)
    #expect(sizes.count == 2)
    #expect(try Snappy.default.uncompressedLength(of: firstChunkBody(of: framed)) == 65_536)
    #expect(try IWAChunkCodec.default.decode(framed) == payload)
  }

  // MARK: - Malformed framing

  @Test("rejects a truncated chunk header")
  internal func rejectsTruncatedHeader() {
    #expect(throws: IWAChunkError.truncatedHeader(offset: 0)) {
      _ = try IWAChunkCodec.default.decode([0x00, 0x01])
    }
  }

  @Test("rejects an unsupported chunk type byte")
  internal func rejectsUnsupportedChunkType() {
    #expect(throws: IWAChunkError.unsupportedChunkType(0x01, offset: 0)) {
      _ = try IWAChunkCodec.default.decode([0x01, 0x00, 0x00, 0x00])
    }
  }

  @Test("rejects a declared length running past the input")
  internal func rejectsTruncatedChunk() {
    #expect(throws: IWAChunkError.truncatedChunk(expected: 9, available: 1)) {
      _ = try IWAChunkCodec.default.decode([0x00, 0x09, 0x00, 0x00, 0x01])
    }
  }

  @Test("rethrows Snappy errors from a corrupt chunk payload")
  internal func rethrowsSnappyErrors() {
    // A one-byte payload of 0x80 is a truncated varint preamble.
    #expect(throws: SnappyError.invalidLengthPreamble) {
      _ = try IWAChunkCodec.default.decode([0x00, 0x01, 0x00, 0x00, 0x80])
    }
  }

  // MARK: - Helpers

  /// Walks chunk headers without decompressing, returning each compressed size.
  private func chunkSizes(of framed: [UInt8]) -> [Int] {
    var sizes: [Int] = []
    var index = 0
    while index + 4 <= framed.count {
      let size =
        Int(framed[index + 1])
        | (Int(framed[index + 2]) << 8)
        | (Int(framed[index + 3]) << 16)
      sizes.append(size)
      index += 4 + size
    }
    return sizes
  }

  /// The compressed body of the first chunk.
  private func firstChunkBody(of framed: [UInt8]) -> [UInt8] {
    let size = Int(framed[1]) | (Int(framed[2]) << 8) | (Int(framed[3]) << 16)
    return Array(framed[4..<(4 + size)])
  }

  /// Deterministic incompressible-ish bytes from a linear congruential
  /// generator, so multi-chunk tests exercise real splits.
  private func pseudoRandom(count: Int) -> [UInt8] {
    var state: UInt64 = 0x5_DEEC_E66D
    var bytes: [UInt8] = []
    bytes.reserveCapacity(count)
    for _ in 0..<count {
      state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
      bytes.append(UInt8(truncatingIfNeeded: state >> 33))
    }
    return bytes
  }
}
