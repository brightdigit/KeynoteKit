import Testing

@testable import Snappy

/// Decoding tests against Apple's own encoder output.
///
/// Round-tripping our encoder against our decoder only proves self-consistency.
/// These blocks were produced by Keynote, so they are the evidence that the
/// codec reads production `.iwa` payloads.
///
/// Note what is deliberately *absent*: no chunk headers, no 64 KiB splitting, no
/// `.iwa` parsing. Those belong to `IWAFraming` (#17). The blocks here were
/// unwrapped from their framing when the fixtures were captured.
@Suite("Snappy against the Keynote corpus")
internal struct AppleCorpusTests {
  @Test("decodes blocks produced by Keynote", arguments: AppleBlockFixtures.all)
  internal func decodesAppleBlock(sample: AppleBlock) throws {
    let decoded = try Snappy.decompress(sample.block)
    #expect(decoded.count == sample.uncompressedCount, "wrong length for \(sample.origin)")
  }

  @Test("agrees with Apple's declared length before decoding", arguments: AppleBlockFixtures.all)
  internal func readsAppleLength(sample: AppleBlock) throws {
    #expect(try Snappy.uncompressedLength(of: sample.block) == sample.uncompressedCount)
  }

  @Test("re-encodes Apple's payloads losslessly", arguments: AppleBlockFixtures.all)
  internal func reencodesAppleBlock(sample: AppleBlock) throws {
    // Byte-identity with Apple is explicitly *not* required — the format leaves
    // encoders wide latitude. What must hold is that our re-encoding decodes
    // back to exactly the same payload.
    let original = try Snappy.decompress(sample.block)
    let recompressed = Snappy.compress(original)
    #expect(try Snappy.decompress(recompressed) == original, "lost data for \(sample.origin)")
  }

  @Test("stays within reach of Apple's compression ratio")
  internal func compressionRatioIsCompetitive() throws {
    var appleTotal = 0
    var oursTotal = 0
    for sample in AppleBlockFixtures.all {
      let original = try Snappy.decompress(sample.block)
      appleTotal += sample.block.count
      oursTotal += Snappy.compress(original).count
    }

    // Apple's encoder is closed-source and may not be stock Snappy, so this is
    // a drift alarm, not a specification. Ours ran ~11% larger when measured.
    #expect(oursTotal < appleTotal * 3 / 2)
  }
}
