import Testing

@testable import KeynoteKitScripting

@Suite("KeynoteScriptingError")
internal struct KeynoteScriptingErrorTests {
  @Test("Apple event error -1743 classifies as an Automation denial")
  internal func automationDenialClassified() {
    let error = KeynoteScriptingError(
      appleEventErrorCode: -1_743,
      message: "Not authorized to send Apple events to Keynote.",
      bundleIdentifier: "com.apple.iWork.Keynote"
    )
    #expect(error == .automationNotPermitted(bundleIdentifier: "com.apple.iWork.Keynote"))
  }

  @Test("other Apple event errors keep their code and message")
  internal func otherErrorsKeepCode() {
    let error = KeynoteScriptingError(
      appleEventErrorCode: -1_728,
      message: "Can't get object.",
      bundleIdentifier: "com.apple.iWork.Keynote"
    )
    #expect(error == .appleEventFailed(code: -1_728, message: "Can't get object."))
  }
}
