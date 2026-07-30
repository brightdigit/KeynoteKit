import Testing

@testable import KeynoteKitScripting

@Suite("TransitionSettings")
internal struct TransitionSettingsTests {
  @Test("defaults mirror an untouched slide")
  internal func defaults() {
    let settings = TransitionSettings()
    #expect(settings.effect == .none)
    #expect(settings.duration == 1.0)
    #expect(settings.delay == 0.0)
    #expect(settings.isAutomatic == false)
  }

  @Test("the record has exactly the four scriptable fields")
  internal func recordHasFourFields() {
    #expect(TransitionSettings.Field.allCases.count == 4)
  }

  @Test("fields lower to their AppleScript property names")
  internal func fieldsLowerToAppleScriptNames() {
    #expect(TransitionSettings.Field.transitionEffect.appleScriptName == "transition effect")
    #expect(TransitionSettings.Field.transitionDuration.appleScriptName == "transition duration")
    #expect(TransitionSettings.Field.transitionDelay.appleScriptName == "transition delay")
    #expect(
      TransitionSettings.Field.automaticTransition.appleScriptName == "automatic transition"
    )
  }

  @Test("fields lower to their Apple event codes")
  internal func fieldsLowerToEventCodes() {
    #expect(TransitionSettings.Field.transitionEffect.eventCode == AppleEventCode("xeft"))
    #expect(TransitionSettings.Field.transitionDuration.eventCode == AppleEventCode("xdur"))
    #expect(TransitionSettings.Field.transitionDelay.eventCode == AppleEventCode("xdly"))
    #expect(TransitionSettings.Field.automaticTransition.eventCode == AppleEventCode("xaut"))
  }

  @Test("fields lower to their sdef Cocoa keys")
  internal func fieldsLowerToCocoaKeys() {
    #expect(TransitionSettings.Field.transitionEffect.cocoaKey == "KNTransitionEffectName")
    #expect(
      TransitionSettings.Field.transitionDuration.cocoaKey == "KNTransitionAttributesDuration"
    )
    #expect(TransitionSettings.Field.transitionDelay.cocoaKey == "KNTransitionAttributesDelay")
    #expect(
      TransitionSettings.Field.automaticTransition.cocoaKey
        == "KNTransitionAttributesIsAutomatic"
    )
  }
}
