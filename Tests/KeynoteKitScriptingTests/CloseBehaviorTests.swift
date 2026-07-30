import Testing

@testable import KeynoteKitScripting

@Suite("CloseBehavior")
internal struct CloseBehaviorTests {
  @Test("behaviors lower to the standard suite's space-padded codes")
  internal func behaviorsLowerToSaveOptions() {
    #expect(CloseBehavior.saving.eventCode == AppleEventCode("yes "))
    #expect(CloseBehavior.notSaving.eventCode == AppleEventCode("no  "))
    #expect(CloseBehavior.askingUser.eventCode == AppleEventCode("ask "))
    #expect(CloseBehavior.allCases.count == 3)
  }
}
