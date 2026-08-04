import Testing

@testable import KeynoteKitScripting

@Suite("KeynoteKitScripting")
internal struct KeynoteKitScriptingTests {
  // MARK: - Namespace Tests

  @Test("Keynote bundle identifier is stable")
  internal func keynoteBundleIdentifier() {
    #expect(KeynoteKitScripting.keynoteBundleIdentifier == "com.apple.iWork.Keynote")
  }
}
