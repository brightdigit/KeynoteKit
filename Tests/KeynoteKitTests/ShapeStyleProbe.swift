import Foundation
import IWAFraming
import KeynoteKit
import KeynoteKitProtobuf
import Testing

/// Shared navigation for the shape-style suites: writes a deck, reopens it,
/// and resolves the fork the first drawable's placeholder points at.
///
/// Extracted from `ShapeStyleTests` when the fill suite (#78) was added —
/// both suites need the same walk, and duplicating it would drift.
internal enum ShapeStyleProbe {
  /// Writes the deck and reopens it as a surgeon.
  internal static func written(_ deck: Deck) throws -> KeynoteArchiveSurgeon {
    let url = FileManager.default.temporaryDirectory
      .appending(path: "shapestyle-\(UUID().uuidString).key")
    defer { try? FileManager.default.removeItem(at: url) }
    try deck.write(to: url)
    return try KeynoteArchiveSurgeon(
      bundle: try KeyBundle(contentsOfZip: Array(try Data(contentsOf: url)))
    )
  }

  /// The first drawable's placeholder archive.
  internal static func firstPlaceholder(
    in surgeon: KeynoteArchiveSurgeon
  ) throws -> KN_PlaceholderArchive {
    let catalog = SlideCatalog(members: surgeon.members)
    let location = try placeholderLocation(in: surgeon, catalog: catalog)
    return try KN_PlaceholderArchive(
      serializedBytes: surgeon.members[location.memberIndex]
        .records[location.recordIndex]
        .payloads[location.payloadIndex],
      partial: true
    )
  }

  /// The shape style referenced by the first drawable's placeholder, with
  /// the placeholder's header reference asserted along the way.
  internal static func referencedShapeStyle(
    in surgeon: KeynoteArchiveSurgeon
  ) throws -> (archive: TSWP_ShapeStyleArchive, identifier: UInt64) {
    let catalog = SlideCatalog(members: surgeon.members)
    let placeholderLocation = try placeholderLocation(in: surgeon, catalog: catalog)
    let placeholderRecord = surgeon.members[placeholderLocation.memberIndex]
      .records[placeholderLocation.recordIndex]
    let placeholder = try KN_PlaceholderArchive(
      serializedBytes: placeholderRecord.payloads[placeholderLocation.payloadIndex],
      partial: true
    )
    let identifier = placeholder.super.super.style.identifier
    #expect(placeholderRecord.info.messageInfos[0].objectReferences.contains(identifier))
    let location = try #require(
      try catalog.locate(recordIdentifier: identifier, named: "TSWP.ShapeStyleArchive")
    )
    let archive = try TSWP_ShapeStyleArchive(
      serializedBytes: surgeon.members[location.memberIndex]
        .records[location.recordIndex]
        .payloads[location.payloadIndex],
      partial: true
    )
    return (archive, identifier)
  }

  /// Asserts the fork's stylesheet and metadata edges.
  internal static func expectRegistered(
    _ identifier: UInt64,
    in surgeon: KeynoteArchiveSurgeon
  ) throws {
    let catalog = SlideCatalog(members: surgeon.members)
    let sheetLocation = try #require(try catalog.locateFirst(named: "TSS.StylesheetArchive"))
    let sheet = try TSS_StylesheetArchive(
      serializedBytes: surgeon.members[sheetLocation.memberIndex]
        .records[sheetLocation.recordIndex]
        .payloads[sheetLocation.payloadIndex],
      partial: true
    )
    #expect(sheet.styles.contains { $0.identifier == identifier })
    let metaLocation = try #require(try catalog.locateFirst(named: "TSP.PackageMetadata"))
    let metadata = try TSP_PackageMetadata(
      serializedBytes: surgeon.members[metaLocation.memberIndex]
        .records[metaLocation.recordIndex]
        .payloads[metaLocation.payloadIndex],
      partial: true
    )
    let slideIdentifier = try #require(try catalog.orderedSlides().first).slideIdentifier
    let slideComponent = try #require(
      metadata.components.first { $0.identifier == slideIdentifier }
    )
    #expect(
      slideComponent.externalReferences.contains { $0.objectIdentifier == identifier }
    )
  }

  /// Locates the first drawable's `KN.PlaceholderArchive`.
  private static func placeholderLocation(
    in surgeon: KeynoteArchiveSurgeon,
    catalog: SlideCatalog
  ) throws -> SlideCatalog.Location {
    let slide = try #require(try catalog.orderedSlides().first)
    let slideArchive = try KN_SlideArchive(
      serializedBytes: surgeon.members[slide.memberIndex].records[slide.recordIndex].payloads[0],
      partial: true
    )
    let drawableIdentifier = try #require(slideArchive.drawablesZOrder.first).identifier
    return try #require(
      try catalog.locate(recordIdentifier: drawableIdentifier, named: "KN.PlaceholderArchive")
    )
  }
}
