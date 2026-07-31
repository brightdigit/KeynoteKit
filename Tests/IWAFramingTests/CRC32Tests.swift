import Testing

@testable import IWAFraming

/// Known-answer coverage: the rest of the suite only compares this CRC-32
/// against itself, which a wrong polynomial or reflection would also pass.
@Suite("CRC32")
internal struct CRC32Tests {
  @Test("matches the standard check value for \"123456789\"")
  internal func matchesCheckValue() {
    #expect(CRC32.checksum(Array("123456789".utf8)[...]) == 0xCBF4_3926)
  }

  @Test("hashes the empty message to zero")
  internal func hashesEmptyToZero() {
    #expect(CRC32.checksum([][...]) == 0)
  }
}
