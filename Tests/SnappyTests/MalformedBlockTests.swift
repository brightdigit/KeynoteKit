import Testing

@testable import Snappy

/// Malformed-input handling.
///
/// `.iwa` bytes come from a file on disk, so a codec that trapped on damaged
/// input would turn a corrupt document into a crash. Every case here must throw.
@Suite("Snappy malformed input")
internal struct MalformedBlockTests {
  @Test("rejects a truncated varint preamble")
  internal func rejectsTruncatedPreamble() {
    #expect(throws: SnappyError.invalidLengthPreamble) {
      _ = try Snappy.default.decompress([0x80])
    }
  }

  @Test("rejects a preamble wider than 32 bits")
  internal func rejectsOverlongPreamble() {
    #expect(throws: SnappyError.invalidLengthPreamble) {
      _ = try Snappy.default.decompress([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F, 0x00])
    }
  }

  @Test("rejects a literal running past the end of the block")
  internal func rejectsTruncatedLiteral() {
    // Declares 5 bytes of literal but supplies 2.
    #expect(throws: SnappyError.truncatedInput) {
      _ = try Snappy.default.decompress([0x05, 0x10, 0x68, 0x65])
    }
  }

  @Test("rejects a missing copy operand")
  internal func rejectsTruncatedCopyOperand() {
    #expect(throws: SnappyError.truncatedInput) {
      _ = try Snappy.default.decompress([0x08, 0x04, 0x61, 0x62, 0x01])
    }
  }

  @Test("rejects a copy offset of zero")
  internal func rejectsZeroOffset() {
    #expect(throws: SnappyError.invalidCopyOffset) {
      _ = try Snappy.default.decompress([0x08, 0x04, 0x61, 0x62, 0x01, 0x00])
    }
  }

  @Test("rejects a copy reaching before the start of the output")
  internal func rejectsOutOfRangeOffset() {
    // Only two bytes decoded so far, but the copy reaches back 255.
    #expect(throws: SnappyError.invalidCopyOffset) {
      _ = try Snappy.default.decompress([0x08, 0x04, 0x61, 0x62, 0x01, 0xFF])
    }
  }

  @Test("rejects output shorter than the preamble promised")
  internal func rejectsLengthMismatch() {
    #expect(throws: SnappyError.lengthMismatch) {
      _ = try Snappy.default.decompress([0x40, 0x04, 0x61, 0x62])
    }
  }

  @Test("rejects a tiny input claiming a ~4 GiB length")
  internal func rejectsHugeClaimedLength() {
    // The preamble alone claims UInt32.max uncompressed bytes; the decoder
    // must fail on the truncated body without reserving that allocation.
    #expect(throws: SnappyError.truncatedInput) {
      _ = try Snappy.default.decompress([0xFF, 0xFF, 0xFF, 0xFF, 0x0F, 0x00])
    }
  }

  @Test("rejects a copy overshooting the promised output length")
  internal func rejectsCopyPastPromisedLength() {
    // Preamble promises 2 bytes; a literal plus a 4-byte copy would emit 5.
    #expect(throws: SnappyError.lengthMismatch) {
      _ = try Snappy.default.decompress([0x02, 0x00, 0x61, 0x01, 0x01])
    }
  }

  @Test("throws rather than traps on arbitrary bytes")
  internal func survivesArbitraryInput() {
    // Deterministic sweep: whatever these decode to, nothing may crash.
    var state: UInt64 = 0x9E37_79B9_7F4A_7C15
    for _ in 0..<2_000 {
      var block = [UInt8]()
      for _ in 0..<32 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        block.append(UInt8(truncatingIfNeeded: state >> 33))
      }
      _ = try? Snappy.default.decompress(block)
    }
  }

  @Test("throws rather than traps on truncations of a valid block")
  internal func survivesTruncatedValidBlock() {
    let valid = Snappy.default.compress(Payload.repeatingText(count: 2_048))
    for length in 0..<valid.count {
      _ = try? Snappy.default.decompress(Array(valid.prefix(length)))
    }
  }

  @Test("throws rather than traps when a valid block is corrupted")
  internal func survivesCorruptedValidBlock() {
    let valid = Snappy.default.compress(Payload.repeatingText(count: 1_024))
    for index in valid.indices {
      var damaged = valid
      damaged[index] ^= 0xFF
      _ = try? Snappy.default.decompress(damaged)
    }
  }
}
