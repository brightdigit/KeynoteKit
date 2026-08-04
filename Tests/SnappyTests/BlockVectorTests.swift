import Testing

@testable import Snappy

/// Decoding tests against hand-built blocks.
///
/// These byte sequences are written out literally rather than produced by our
/// own encoder, so they test conformance to the format instead of merely
/// agreeing with ourselves.
@Suite("Snappy block vectors")
internal struct BlockVectorTests {
  // MARK: - Literals

  @Test("decodes an inline literal")
  internal func decodesInlineLiteral() throws {
    // preamble 5; tag (5-1)<<2 = 0x10; "hello"
    let block: [UInt8] = [0x05, 0x10, 0x68, 0x65, 0x6C, 0x6C, 0x6F]
    #expect(try Snappy.default.decompress(block) == Array("hello".utf8))
  }

  @Test("decodes an empty block")
  internal func decodesEmptyBlock() throws {
    #expect(try Snappy.default.decompress([0x00]).isEmpty)
  }

  @Test("decodes a literal whose length is stored in one extra byte")
  internal func decodesExtendedLiteral() throws {
    // Lengths above 60 move the count out of the tag: selector 60 => tag 0xF0.
    let payload = [UInt8](repeating: 0x7A, count: 100)
    var block: [UInt8] = [100, 0xF0, 99]
    block.append(contentsOf: payload)
    #expect(try Snappy.default.decompress(block) == payload)
  }

  // MARK: - Copies

  @Test("decodes a one-byte-offset copy")
  internal func decodesCopy1() throws {
    // "ab" then a 4-byte copy from offset 2 => "ababab" (6 bytes total).
    // tag: (4-4)<<2 | (2>>8)<<5 | 0x01 = 0x01, operand 0x02.
    let block: [UInt8] = [0x06, 0x04, 0x61, 0x62, 0x01, 0x02]
    #expect(try Snappy.default.decompress(block) == Array("ababab".utf8))
  }

  @Test("decodes a one-byte-offset copy reaching past 255")
  internal func decodesCopy1LargeOffset() throws {
    // Copy1 offsets carry bits 8...10 in the tag's high bits; an offset of
    // 260 exercises them where a single operand byte cannot.
    let literal = (0..<300).map { UInt8($0 % 251) }
    // Preamble 304; literal selector 61 (0xF4) with a 2-byte length of 299;
    // copy1 tag (260>>8)<<5 | (4-4)<<2 | 0x01 = 0x21, operand 260 & 0xFF.
    var block: [UInt8] = [0xB0, 0x02, 0xF4, 0x2B, 0x01]
    block.append(contentsOf: literal)
    block.append(contentsOf: [0x21, 0x04])
    #expect(try Snappy.default.decompress(block) == literal + literal[40..<44])
  }

  @Test("decodes a two-byte-offset copy")
  internal func decodesCopy2() throws {
    // 300 bytes of literal, then a 10-byte copy reaching back 300.
    let literal = (0..<300).map { UInt8($0 % 251) }
    // Preamble 310; literal selector 61 (0xF4) with a 2-byte length of 299.
    var block: [UInt8] = [0xB6, 0x02, 0xF4, 0x2B, 0x01]
    block.append(contentsOf: literal)
    block.append(contentsOf: [UInt8((10 - 1) << 2) | 0x02, 0x2C, 0x01])

    let expected = literal + literal.prefix(10)
    #expect(try Snappy.default.decompress(block) == expected)
  }

  /// The `.iwa` corpus never exercises the four-byte-offset copy form — Apple
  /// chunks at 64 KiB, so no offset ever needs more than two bytes. This vector
  /// is synthetic precisely because fixtures cannot cover it.
  @Test("decodes a four-byte-offset copy")
  internal func decodesCopy4() throws {
    let literal = (0..<300).map { UInt8($0 % 251) }
    // Preamble 310; literal selector 61 (0xF4) with a 2-byte length of 299.
    var block: [UInt8] = [0xB6, 0x02, 0xF4, 0x2B, 0x01]
    block.append(contentsOf: literal)
    // tag 0x03 with a 32-bit little-endian offset of 300.
    block.append(contentsOf: [UInt8((10 - 1) << 2) | 0x03, 0x2C, 0x01, 0x00, 0x00])

    let expected = literal + literal.prefix(10)
    #expect(try Snappy.default.decompress(block) == expected)
  }

  @Test("replays overlapping copies byte by byte")
  internal func decodesOverlappingCopy() throws {
    // One "a", then a 10-byte copy at offset 1: the classic run-length case,
    // where the source advances into bytes the copy itself writes.
    let block: [UInt8] = [0x0B, 0x00, 0x61, UInt8((10 - 1) << 2) | 0x02, 0x01, 0x00]
    #expect(try Snappy.default.decompress(block) == Array(repeating: UInt8(0x61), count: 11))
  }

  // MARK: - Cross-checks

  @Test("our encoder's output decodes to the original")
  internal func encoderOutputDecodes() throws {
    let bytes = Array("banana banana banana banana".utf8)
    let compressed = Snappy.default.compress(bytes)
    #expect(compressed.count < bytes.count)
    #expect(try Snappy.default.decompress(compressed) == bytes)
  }

  @Test("emits copies rather than pure literals for repeated input")
  internal func emitsCopies() {
    // A literal-only encoding of 4 KiB could not fit in 200 bytes, so this
    // pins that the match finder actually runs.
    let compressed = Snappy.default.compress([UInt8](repeating: 0x42, count: 4_096))
    #expect(compressed.count < 200)
  }
}
