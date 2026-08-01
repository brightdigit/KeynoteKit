import Foundation
import IWAFraming
import KeynoteKit
import KeynoteKitProtobuf
import Testing

/// `TextListStyle` (#51 step 2): theme styles repoint without minting;
/// custom bullets, numbering, and indents mint a variation off the matching
/// theme style with every registration edge Keynote needs.
@Suite("TextListStyle")
internal struct TextListStyleTests {
  @Test("theme bullet repoints without minting")
  internal func themeBulletRepoints() throws {
    let surgeon = try written(
      Deck {
        Slide {
          TextBox("Bulleted").listStyle(.bullet)
        }
      }
    )
    let referenced = try referencedListStyle(in: surgeon)
    #expect(referenced.archive.super.styleIdentifier.hasSuffix("liststyle-Bullet"))
    #expect(!referenced.archive.super.isVariation)
  }

  @Test("custom bullet mints a variation off the theme bullet")
  internal func customBulletMintsVariation() throws {
    let surgeon = try written(
      Deck {
        Slide {
          TextBox("Arrows").listStyle(.bullet("→"))
        }
      }
    )
    let referenced = try referencedListStyle(in: surgeon)
    let archive = referenced.archive
    #expect(archive.super.isVariation)
    #expect(archive.labelTypes == Array(repeating: .kString, count: 9))
    #expect(archive.strings == Array(repeating: "→", count: 9))
    #expect(archive.overrideCount == 2)
    let parent = try listStyleArchive(archive.super.parent.identifier, in: surgeon)
    #expect(parent.super.styleIdentifier.hasSuffix("liststyle-Bullet"))
    try expectFullyRegistered(
      referenced.identifier,
      parentIdentifier: archive.super.parent.identifier,
      in: surgeon
    )
  }

  @Test("numbered mints a variation off the theme numbered style")
  internal func numberedMintsOffNumbered() throws {
    let surgeon = try written(
      Deck {
        Slide {
          TextBox("Ordered").listStyle(.numbered())
        }
      }
    )
    let referenced = try referencedListStyle(in: surgeon)
    let archive = referenced.archive
    #expect(archive.super.isVariation)
    #expect(archive.labelTypes == Array(repeating: .kNumber, count: 9))
    #expect(archive.numberTypes == Array(repeating: .kNumericDecimal, count: 9))
    let parent = try listStyleArchive(archive.super.parent.identifier, in: surgeon)
    #expect(parent.super.styleIdentifier.hasSuffix("liststyle-Numbered"))
  }

  @Test("indent mints, inheriting the theme label")
  internal func indentMintsWithInheritedLabels() throws {
    let surgeon = try written(
      Deck {
        Slide {
          TextBox("Indented").listStyle(.bullet.indent(24))
        }
      }
    )
    let referenced = try referencedListStyle(in: surgeon)
    let archive = referenced.archive
    #expect(archive.super.isVariation)
    #expect(archive.labelTypes.isEmpty)
    #expect(archive.indents == Array(repeating: Float(24), count: 9))
    #expect(archive.overrideCount == 1)
    let parent = try listStyleArchive(archive.super.parent.identifier, in: surgeon)
    #expect(parent.super.styleIdentifier.hasSuffix("liststyle-Bullet"))
  }

  /// Writes the deck and reopens it as a surgeon.
  private func written(_ deck: Deck) throws -> KeynoteArchiveSurgeon {
    let url = FileManager.default.temporaryDirectory
      .appending(path: "textliststyle-\(UUID().uuidString).key")
    defer { try? FileManager.default.removeItem(at: url) }
    try deck.write(to: url)
    return try KeynoteArchiveSurgeon(
      bundle: try KeyBundle(contentsOfZip: Array(try Data(contentsOf: url)))
    )
  }

  /// The list style referenced by the first drawable's storage, plus its
  /// record identifier; asserts the header reference along the way.
  private func referencedListStyle(
    in surgeon: KeynoteArchiveSurgeon
  ) throws -> (archive: TSWP_ListStyleArchive, identifier: UInt64) {
    let catalog = SlideCatalog(members: surgeon.members)
    let slide = try #require(try catalog.orderedSlides().first)
    let slideArchive = try KN_SlideArchive(
      serializedBytes: surgeon.members[slide.memberIndex].records[slide.recordIndex].payloads[0],
      partial: true
    )
    let drawableIdentifier = try #require(slideArchive.drawablesZOrder.first).identifier
    let placeholderLocation = try #require(
      try catalog.locate(recordIdentifier: drawableIdentifier, named: "KN.PlaceholderArchive")
    )
    let placeholder = try KN_PlaceholderArchive(
      serializedBytes: surgeon.members[placeholderLocation.memberIndex]
        .records[placeholderLocation.recordIndex]
        .payloads[placeholderLocation.payloadIndex],
      partial: true
    )
    let storageLocation = try #require(
      try catalog.locate(
        recordIdentifier: placeholder.super.ownedStorage.identifier,
        named: "TSWP.StorageArchive"
      )
    )
    let storageRecord = surgeon.members[storageLocation.memberIndex]
      .records[storageLocation.recordIndex]
    let storage = try TSWP_StorageArchive(
      serializedBytes: storageRecord.payloads[storageLocation.payloadIndex],
      partial: true
    )
    let identifier = try #require(storage.tableListStyle.entries.first).object.identifier
    #expect(storageRecord.info.messageInfos[0].objectReferences.contains(identifier))
    return (try listStyleArchive(identifier, in: surgeon), identifier)
  }

  /// Decodes the list style record with `identifier`.
  private func listStyleArchive(
    _ identifier: UInt64,
    in surgeon: KeynoteArchiveSurgeon
  ) throws -> TSWP_ListStyleArchive {
    let catalog = SlideCatalog(members: surgeon.members)
    let location = try #require(
      try catalog.locate(recordIdentifier: identifier, named: "TSWP.ListStyleArchive")
    )
    return try TSWP_ListStyleArchive(
      serializedBytes: surgeon.members[location.memberIndex]
        .records[location.recordIndex]
        .payloads[location.payloadIndex],
      partial: true
    )
  }

  /// Asserts the remaining registration edges of a minted list style:
  /// stylesheet `styles`, the parent's variation-map entry, the slide
  /// component's external reference, and uuid-map entries in both the
  /// stylesheet and slide components.
  private func expectFullyRegistered(
    _ identifier: UInt64,
    parentIdentifier: UInt64,
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
    let variationEntry = sheet.parentToChildrenStyleMap.first {
      $0.parent.identifier == parentIdentifier
    }
    #expect(variationEntry?.children.contains { $0.identifier == identifier } == true)

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
    let componentsWithEntry = metadata.components.filter { component in
      component.objectUuidMapEntries.contains { $0.identifier == identifier }
    }
    #expect(componentsWithEntry.count >= 2)
  }
}
