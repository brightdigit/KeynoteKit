import Testing

@testable import KeynoteKitScripting

@Suite("KeynoteKitScripting")
internal struct KeynoteKitScriptingTests {
  // MARK: - Initialization Tests

  @Test("module is linkable")
  internal func moduleIsLinkable() {
    #expect(KeynoteKitScripting.version == "0.1.0")
  }
}
