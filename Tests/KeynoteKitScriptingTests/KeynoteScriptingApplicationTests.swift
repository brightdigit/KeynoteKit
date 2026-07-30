#if canImport(ScriptingBridge)
  import Testing

  @testable import KeynoteKitScripting

  // These tests never send an Apple event: constructing a session (or
  // failing to) touches only Launch Services, so Keynote is neither
  // launched nor activated. Anything that would send an event lives in
  // `LiveKeynoteTests`, gated behind KEYNOTEKIT_LIVE_KEYNOTE=1.
  @Suite("KeynoteScriptingApplication")
  internal struct KeynoteScriptingApplicationTests {
    @Test("an uninstalled bundle identifier throws applicationNotFound")
    internal func uninstalledBundleIdentifierThrows() {
      let bogus = "com.brightdigit.keynotekit.no-such-app"
      #expect(throws: KeynoteScriptingError.applicationNotFound(bundleIdentifier: bogus)) {
        _ = try KeynoteScriptingApplication(bundleIdentifier: bogus)
      }
    }
  }
#endif
