import Testing

@testable import Snappy

@Suite("Snappy")
internal struct SnappyTests {
  // MARK: - Initialization Tests

  @Test("module is linkable")
  internal func moduleIsLinkable() {
    #expect(Snappy.version == "0.1.0")
  }
}
