import Foundation
import IWAFraming
import KeynoteKit
import KeynoteKitProtobuf
import Testing

/// Plain-by-default (#51 step 1): every authored text box's storage repoints
/// `tableListStyle` at the theme's None list style — the cloned body
/// placeholder inherits the theme bullet otherwise.
@Suite("List style defaults")
internal struct ListStyleTests {
  @Test("bare TextBox repoints tableListStyle at the theme None style")
  internal func bareTextBoxIsPlain() throws {
    let deck = Deck {
      Slide {
        TextBox("Plain by default")
      }
    }
    try assertFirstStorageIsPlain(in: deck)
  }

  @Test("formatted TextBox is also plain by default")
  internal func formattedTextBoxIsPlain() throws {
    let deck = Deck {
      Slide {
        TextBox("Styled").bold().fontSize(30)
      }
    }
    try assertFirstStorageIsPlain(in: deck)
  }

  /// Asserts the first drawable's storage references a list style whose
  /// identifier ends in `liststyle-None`, with the reference mirrored on the
  /// storage record's header.
  private func assertFirstStorageIsPlain(in deck: Deck) throws {
    let surgeon = try authorSurgeon(from: deck)
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
    let entry = try #require(storage.tableListStyle.entries.first)
    #expect(storage.tableListStyle.entries.count == 1)
    #expect(entry.characterIndex == 0)
    let listStyleLocation = try #require(
      try catalog.locate(
        recordIdentifier: entry.object.identifier,
        named: "TSWP.ListStyleArchive"
      )
    )
    let listStyle = try TSWP_ListStyleArchive(
      serializedBytes: surgeon.members[listStyleLocation.memberIndex]
        .records[listStyleLocation.recordIndex]
        .payloads[listStyleLocation.payloadIndex],
      partial: true
    )
    #expect(listStyle.super.styleIdentifier.hasSuffix("liststyle-None"))
    let references = try #require(storageRecord.info.messageInfos.first).objectReferences
    #expect(references.contains(entry.object.identifier))
  }

  /// Authors `deck` and returns a surgeon over the result.
  private func authorSurgeon(from deck: Deck) throws -> KeynoteArchiveSurgeon {
    let url = FileManager.default.temporaryDirectory
      .appending(path: "liststyle-\(UUID().uuidString).key")
    defer { try? FileManager.default.removeItem(at: url) }
    try deck.write(to: url)
    let bundle = try KeyBundle(contentsOfZip: Array(try Data(contentsOf: url)))
    return try KeynoteArchiveSurgeon(bundle: bundle)
  }
}
