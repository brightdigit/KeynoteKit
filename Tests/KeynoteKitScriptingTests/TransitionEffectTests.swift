import Testing

@testable import KeynoteKitScripting

@Suite("TransitionEffect")
internal struct TransitionEffectTests {
  @Test("catalog carries every Keynote 15.3 enumerator")
  internal func catalogIsComplete() {
    #expect(TransitionEffect.catalog.count == 44)
  }

  @Test("catalog identities are unique on every axis")
  internal func catalogIdentitiesAreUnique() {
    let catalog = TransitionEffect.catalog
    #expect(Set(catalog.map(\.appleScriptName)).count == catalog.count)
    #expect(Set(catalog.map(\.eventCode)).count == catalog.count)
    #expect(Set(catalog.map(\.archiveValue)).count == catalog.count)
  }

  @Test("verified effects lower to their sdef identities")
  internal func verifiedEffectsLower() {
    #expect(TransitionEffect.none.eventCode == AppleEventCode("tnil"))
    #expect(TransitionEffect.none.archiveValue == "none")
    #expect(TransitionEffect.dissolve.eventCode == AppleEventCode("tdis"))
    #expect(TransitionEffect.dissolve.archiveValue == "apple:dissolve")
    #expect(TransitionEffect.magicMove.eventCode == AppleEventCode("tmjv"))
    #expect(TransitionEffect.magicMove.archiveValue == "apple:magic-move-implied-motion-path")
    #expect(TransitionEffect.push.archiveValue == "apple:push")
    #expect(TransitionEffect.moveIn.archiveValue == "apple:slide")
  }

  @Test("two-word AppleScript enumerator terms are preserved")
  internal func twoWordTermsPreserved() {
    #expect(TransitionEffect.magicMove.appleScriptName == "magic move")
    #expect(TransitionEffect.fadeThroughColor.appleScriptName == "fade through color")
  }

  @Test("radial wipe's archive string genuinely contains a space")
  internal func radialWipeContainsSpace() {
    #expect(TransitionEffect.radialWipe.archiveValue == "apple:radial wipe")
  }

  @Test("matching finds cataloged archive strings and rejects unknowns")
  internal func matchingLooksUpArchiveValues() {
    #expect(TransitionEffect.matching(archiveValue: "apple:dissolve") == .dissolve)
    #expect(TransitionEffect.matching(archiveValue: "apple:not-a-real-effect") == nil)
  }

  @Test("resolving preserves unknown archive strings as stand-ins")
  internal func resolvingPreservesUnknowns() {
    let unknown = TransitionEffect.resolving(archiveValue: "apple:from-the-future")
    #expect(unknown.archiveValue == "apple:from-the-future")
    #expect(unknown.appleScriptName.isEmpty)
    #expect(unknown.eventCode.rawValue == 0)
    #expect(TransitionEffect.resolving(archiveValue: "apple:dissolve") == .dissolve)
  }
}
