import Testing

@testable import KeynoteKitScripting

@Suite("AppleEventCode")
internal struct AppleEventCodeTests {
  @Test("packs four ASCII characters big-endian")
  internal func packsFourCharacters() {
    #expect(AppleEventCode("tdis").rawValue == 0x7464_6973)
  }

  @Test("round-trips through the four-character spelling")
  internal func roundTripsSpelling() {
    let code = AppleEventCode("Knff")
    #expect(code.fourCharacterCode == "Knff")
    #expect(AppleEventCode(rawValue: code.rawValue) == code)
  }

  @Test("supports space-padded standard suite codes")
  internal func spacePaddedCodes() {
    #expect(AppleEventCode("yes ").fourCharacterCode == "yes ")
    #expect(AppleEventCode("no  ").rawValue == 0x6E6F_2020)
  }
}
