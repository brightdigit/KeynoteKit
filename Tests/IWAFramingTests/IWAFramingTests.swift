import Testing

@testable import IWAFraming

@Suite("IWAFraming")
internal struct IWAFramingTests {
  // MARK: - Initialization Tests

  @Test("module is linkable")
  internal func moduleIsLinkable() {
    #expect(IWAFraming.version == "0.1.0")
  }
}
