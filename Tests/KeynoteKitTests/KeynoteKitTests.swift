import Testing

@testable import KeynoteKit

@Suite("KeynoteKit")
internal struct KeynoteKitTests {
  // MARK: - Initialization Tests

  @Test("module is linkable")
  internal func moduleIsLinkable() {
    #expect(KeynoteKit.version == "0.1.0")
  }
}
