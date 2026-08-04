#if canImport(ScriptingBridge)
  import Testing

  @testable import KeynoteKitScripting

  @Suite("TransitionSettings ScriptingBridge record")
  internal struct TransitionSettingsRecordTests {
    @Test("lowers to a Cocoa-keyed record with the archive effect string")
    internal func lowersToCocoaKeyedRecord() {
      let settings = TransitionSettings(
        effect: .dissolve,
        duration: 2.5,
        delay: 0.5,
        isAutomatic: true
      )
      let record = settings.scriptingBridgeRecord
      #expect(record.count == 4)
      #expect(record["KNTransitionEffectName"] as? String == "apple:dissolve")
      #expect(record["KNTransitionAttributesDuration"] as? Double == 2.5)
      #expect(record["KNTransitionAttributesDelay"] as? Double == 0.5)
      #expect(record["KNTransitionAttributesIsAutomatic"] as? Bool == true)
    }

    @Test("round-trips through the record representation")
    internal func roundTripsThroughRecord() {
      let settings = TransitionSettings(
        effect: .magicMove,
        duration: 1.5,
        delay: 0.25,
        isAutomatic: false
      )
      let parsed = TransitionSettings(scriptingBridgeRecord: settings.scriptingBridgeRecord)
      #expect(parsed == settings)
    }

    @Test("parses an empty record as the defaults")
    internal func parsesEmptyRecordAsDefaults() {
      let parsed = TransitionSettings(scriptingBridgeRecord: [:])
      #expect(parsed == TransitionSettings())
    }

    @Test("preserves an unknown effect string from a newer Keynote")
    internal func preservesUnknownEffect() {
      let record: [String: Any] = ["KNTransitionEffectName": "apple:from-the-future"]
      let parsed = TransitionSettings(scriptingBridgeRecord: record)
      #expect(parsed.effect.archiveValue == "apple:from-the-future")
      #expect(parsed.duration == 1.0)
    }
  }
#endif
