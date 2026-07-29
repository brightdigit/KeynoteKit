import Testing

@testable import KeynoteKitProtobuf

@Suite("KeynoteKitProtobuf")
internal struct KeynoteKitProtobufTests {
  // MARK: - Initialization Tests

  @Test("module is linkable")
  internal func moduleIsLinkable() {
    #expect(KeynoteKitProtobuf.schemaVersion == "15.3")
    #expect(KeynoteKitProtobuf.registryVersion == "14.4")
  }
}
