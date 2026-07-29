import SwiftProtobuf
import Testing

@testable import KeynoteKitProtobuf

/// Mirrors the Python acceptance oracle `mise run prepare-keynote-parser`,
/// which prints `631 registry entries; 0 missing message names`.
@Suite("TSPRegistryMapping")
internal struct TSPRegistryMappingTests {
  /// Archive types the research findings name explicitly. Each must decode.
  private static let archiveTypesFromFindings = [
    "KN.BuildArchive",
    "KN.BuildChunkArchive",
    "KN.ShowArchive",
    "KN.SlideArchive",
    "KN.SlideNodeArchive",
    "TSCE.FormulaOwnerDependenciesArchive",
    "TSCE.TrackedReferenceStoreArchive",
    "TST.HeaderNameMgrArchive",
    "TSWP.CharacterStyleArchive",
    "TSWP.ParagraphStyleArchive",
    "TSWP.ShapeStyleArchive",
  ]

  // MARK: - Oracle Tests

  @Test("registry has 631 entries")
  internal func registryHasSixHundredThirtyOneEntries() {
    #expect(TSPRegistryMapping.count == 631)
    #expect(TSPRegistryMapping.identifiers.count == 631)
  }

  @Test("every registered message name resolves to a generated Swift type")
  internal func everyMessageNameResolves() {
    let unresolved = TSPRegistryMapping.identifiers.filter {
      TSPRegistryMapping.messageType(for: $0) == nil
    }
    #expect(unresolved.isEmpty, "unresolved identifiers: \(unresolved)")
  }

  @Test("each Swift type reports the proto name the registry recorded")
  internal func swiftTypesReportTheirProtoName() {
    // Guards against a transcription that pairs a name with the wrong type:
    // `protoMessageName` comes from the .proto, not from this table.
    for identifier in TSPRegistryMapping.identifiers {
      guard
        let name = TSPRegistryMapping.messageName(for: identifier),
        let messageType = TSPRegistryMapping.messageType(for: identifier)
      else {
        Issue.record("identifier \(identifier) did not resolve")
        continue
      }
      #expect(messageType.protoMessageName == name)
    }
  }

  // MARK: - Table Shape Tests

  @Test("identifiers are sparse and span the documented range")
  internal func identifiersSpanDocumentedRange() {
    let identifiers = TSPRegistryMapping.identifiers
    #expect(identifiers.first == 1)
    #expect(identifiers.last == 11_027)
    // Sparse: far fewer entries than the range they cover.
    #expect(identifiers.count < 11_027)
  }

  @Test("known identifiers map to their documented archives")
  internal func knownIdentifiersMapCorrectly() {
    #expect(TSPRegistryMapping.messageName(for: 1) == "KN.DocumentArchive")
    #expect(TSPRegistryMapping.messageName(for: 2) == "KN.ShowArchive")
    #expect(TSPRegistryMapping.messageName(for: 8) == "KN.BuildArchive")
    #expect(TSPRegistryMapping.messageName(for: 153) == "KN.BuildChunkArchive")
  }

  @Test("message names are not unique across identifiers")
  internal func messageNamesAreNotUnique() {
    // The registry aliases: inverting it with unique keys would trap.
    #expect(TSPRegistryMapping.messageName(for: 5) == "KN.SlideArchive")
    #expect(TSPRegistryMapping.messageName(for: 6) == "KN.SlideArchive")
    #expect(TSPRegistryMapping.messageName(for: 7) == "KN.PlaceholderArchive")
    #expect(TSPRegistryMapping.messageName(for: 12) == "KN.PlaceholderArchive")

    let distinct = Set(TSPRegistryMapping.identifiers.compactMap(TSPRegistryMapping.messageName))
    #expect(distinct.count == 624)
  }

  @Test("unregistered identifiers resolve to nil")
  internal func unregisteredIdentifiersResolveToNil() {
    #expect(TSPRegistryMapping.messageName(for: 0) == nil)
    #expect(TSPRegistryMapping.messageType(for: 999_999) == nil)
  }

  // MARK: - Decoding Tests

  @Test(
    "archive types named in the findings decode",
    arguments: TSPRegistryMappingTests.archiveTypesFromFindings
  )
  internal func findingsArchiveTypesDecode(_ name: String) throws {
    let messageType = try #require(
      TSPRegistryMapping.messageType(forName: name),
      "\(name) has no generated Swift type"
    )
    #expect(messageType.protoMessageName == name)

    // These are proto2 messages and 1,497 of their fields are `required`, so a
    // strict decode of an empty body throws `.missingRequiredFields`. Partial
    // decoding is what the reader wants anyway: a 15.3 schema paired with a
    // 14.4 registry must tolerate fields one side considers mandatory.
    let decoded = try messageType.init(serializedBytes: [] as [UInt8], partial: true)
    #expect(Swift.type(of: decoded).protoMessageName == name)

    // Round-trip: whatever these bytes serialize back to must re-decode.
    let bytes: [UInt8] = try decoded.serializedBytes(partial: true)
    #expect(bytes.isEmpty)
    _ = try messageType.init(serializedBytes: bytes, partial: true)
  }

  @Test("decode resolves an identifier to a live message")
  internal func decodeResolvesIdentifier() throws {
    let build = try TSPRegistryMapping.decode(identifier: 8, serializedBytes: [])
    #expect(Swift.type(of: build).protoMessageName == "KN.BuildArchive")

    let chunk = try TSPRegistryMapping.decode(identifier: 153, serializedBytes: [])
    #expect(Swift.type(of: chunk).protoMessageName == "KN.BuildChunkArchive")
  }

  @Test("decode rejects an unregistered identifier")
  internal func decodeRejectsUnregisteredIdentifier() {
    #expect(throws: TSPRegistryError.unknownIdentifier(999_999)) {
      try TSPRegistryMapping.decode(identifier: 999_999, serializedBytes: [])
    }
  }

  @Test("every registered identifier decodes and round-trips")
  internal func everyRegisteredIdentifierDecodes() throws {
    // The broad form of the "every archive type decodes" criterion: not just
    // the ones the findings name, but all 631 identifiers the registry reaches.
    for identifier in TSPRegistryMapping.identifiers {
      let name = try #require(TSPRegistryMapping.messageName(for: identifier))
      let message = try TSPRegistryMapping.decode(identifier: identifier, serializedBytes: [])
      #expect(Swift.type(of: message).protoMessageName == name)

      let bytes: [UInt8] = try message.serializedBytes(partial: true)
      #expect(bytes.isEmpty, "\(name) emitted defaults")
    }
  }
}
