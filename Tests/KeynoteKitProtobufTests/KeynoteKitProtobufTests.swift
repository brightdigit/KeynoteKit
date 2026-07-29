import Testing

@testable import KeynoteKitProtobuf

@Suite("KeynoteKitProtobuf")
internal struct KeynoteKitProtobufTests {
  // MARK: - Initialization Tests

  @Test("module is linkable")
  internal func moduleIsLinkable() {
    #expect(KeynoteKitProtobuf.version == "0.1.0")
  }
}
