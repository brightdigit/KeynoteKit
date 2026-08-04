import Foundation
import IWAFraming
import KeynoteKit
import KeynoteKitProtobuf
import Testing

/// Multi-paragraph item formatting (#81).
///
/// The surgeon used to collapse runs of identical paragraph formats into a
/// single `tableParaStyle` entry at offset 0. Keynote then styled only the
/// first paragraph and rendered the rest at the template default — silently,
/// since the archive stayed valid.
///
/// Keynote's own shape is one entry per paragraph, repeats carrying
/// identifier 0 ("same as previous"): a human-authored 5-paragraph body in
/// `build_action_B.key` holds five entries, `char 0 -> 2651127` then
/// `char 15/30/47/63 -> 0`.
@Suite("Multi-paragraph formatting")
internal struct MultiParagraphFormattingTests {
  /// The #81 regression guard: item-level font/size/color on a
  /// **three**-paragraph box must produce an entry per paragraph, so
  /// Keynote styles every line rather than only the first.
  @Test("item-level font and color reach every paragraph of a 3-paragraph box")
  internal func itemFormattingSpansAllParagraphs() throws {
    let surgeon = try written(
      Deck {
        Slide {
          TextBox("iiii\nMMMM\n1111")
            .font("Menlo", size: 96)
            .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.9))
        }
      }
    )
    let storage = try firstStorage(in: surgeon)
    let entries = storage.archive.tableParaStyle.entries
    try #require(entries.count == 3)
    #expect(entries.map(\.characterIndex) == [0, 5, 10])
    let fork = try paragraphStyle(entries[0].object.identifier, in: surgeon)
    #expect(fork.charProperties.fontName == "Menlo")
    #expect(fork.charProperties.fontSize == 96)
    // Interior and trailing paragraphs repeat the same format.
    #expect(entries[1].object.identifier == 0)
    #expect(entries[2].object.identifier == 0)
  }

  /// A repeat entry must leave `object` ABSENT, not set to identifier 0.
  ///
  /// Setting it materializes a present-but-empty reference, which Keynote
  /// resolves to nil and **crashes** on — the standing id-0 trap. Asserting
  /// `identifier == 0` alone does not catch it, because an absent message
  /// and a zeroed one both read back as 0. The template's own repeat entries
  /// serialize as `[08 0f]`: character index only.
  @Test("repeat entries omit the object field rather than zeroing it")
  internal func repeatEntriesOmitObject() throws {
    let surgeon = try written(
      Deck {
        Slide {
          TextBox("one\ntwo\nthree").fontSize(48)
        }
      }
    )
    let storage = try firstStorage(in: surgeon)
    let entries = storage.archive.tableParaStyle.entries
    try #require(entries.count == 3)
    #expect(entries[0].hasObject)
    #expect(!entries[1].hasObject)
    #expect(!entries[2].hasObject)
    // The wire bytes of a repeat carry only the character index.
    let bytes: [UInt8] = try entries[1].serializedBytes(partial: true)
    #expect(bytes == [0x08, 0x04])
  }

  /// Writes the deck and reopens it as a surgeon.
  private func written(_ deck: Deck) throws -> KeynoteArchiveSurgeon {
    let url = FileManager.default.temporaryDirectory
      .appending(path: "paragraphs-\(UUID().uuidString).key")
    defer { try? FileManager.default.removeItem(at: url) }
    try deck.write(to: url)
    return try KeynoteArchiveSurgeon(
      bundle: try KeyBundle(contentsOfZip: Array(try Data(contentsOf: url)))
    )
  }

  /// The first drawable's storage archive and its record.
  private func firstStorage(
    in surgeon: KeynoteArchiveSurgeon
  ) throws -> (archive: TSWP_StorageArchive, record: TSPArchiveRecord) {
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
    let location = try #require(
      try catalog.locate(
        recordIdentifier: placeholder.super.ownedStorage.identifier,
        named: "TSWP.StorageArchive"
      )
    )
    let record = surgeon.members[location.memberIndex].records[location.recordIndex]
    let archive = try TSWP_StorageArchive(
      serializedBytes: record.payloads[location.payloadIndex],
      partial: true
    )
    return (archive, record)
  }

  /// Decodes the paragraph style with `identifier`.
  private func paragraphStyle(
    _ identifier: UInt64,
    in surgeon: KeynoteArchiveSurgeon
  ) throws -> TSWP_ParagraphStyleArchive {
    let catalog = SlideCatalog(members: surgeon.members)
    let location = try #require(
      try catalog.locate(recordIdentifier: identifier, named: "TSWP.ParagraphStyleArchive")
    )
    return try TSWP_ParagraphStyleArchive(
      serializedBytes: surgeon.members[location.memberIndex]
        .records[location.recordIndex]
        .payloads[location.payloadIndex],
      partial: true
    )
  }
}
