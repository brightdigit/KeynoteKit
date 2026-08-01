import Foundation
import IWAFraming
import KeynoteKit
import KeynoteKitProtobuf
import Testing

/// `Paragraph` semantics (#51 step 4): each bare `Text` is its own
/// paragraph; per-paragraph alignment/indent mint one fork per distinct
/// effective format, entries keyed by UTF-16 start offsets.
@Suite("Paragraphs")
internal struct ParagraphTests {
  @Test("bare Texts split into their own paragraphs")
  internal func bareTextsSplit() throws {
    let surgeon = try written(
      Deck {
        Slide {
          TextBox {
            Text("alpha")
            Text("beta")
          }
        }
      }
    )
    #expect(try firstStorage(in: surgeon).archive.text == ["alpha\nbeta"])
  }

  @Test("newlines in a plain string split into paragraphs")
  internal func newlinesSplit() throws {
    let surgeon = try written(
      Deck {
        Slide {
          TextBox("one\ntwo")
        }
      }
    )
    #expect(try firstStorage(in: surgeon).archive.text == ["one\ntwo"])
  }

  @Test("item-wide alignment mints one deduped fork at offset zero")
  internal func itemWideAlignment() throws {
    let surgeon = try written(
      Deck {
        Slide {
          TextBox("one\ntwo").textAlignment(.center)
        }
      }
    )
    let storage = try firstStorage(in: surgeon)
    try #require(storage.archive.tableParaStyle.entries.count == 1)
    let entry = storage.archive.tableParaStyle.entries[0]
    #expect(entry.characterIndex == 0)
    let fork = try paragraphStyle(entry.object.identifier, in: surgeon)
    #expect(fork.super.isVariation)
    #expect(fork.paraProperties.alignment == .tatvalue2)
    #expect(fork.overrideCount == 1)
  }

  @Test("distinct indents mint one fork per paragraph at UTF-16 offsets")
  internal func distinctIndentsPerParagraph() throws {
    let surgeon = try written(
      Deck {
        Slide {
          TextBox {
            Paragraph("🎉 lead").indent(10)
            Paragraph("middle").indent(20, firstLine: 30)
            Paragraph("tail").alignment(.right)
          }
        }
      }
    )
    let storage = try firstStorage(in: surgeon)
    let entries = storage.archive.tableParaStyle.entries
    try #require(entries.count == 3)
    // "🎉 lead" is 7 UTF-16 units (surrogate pair + " lead"), + 1 for "\n".
    #expect(entries.map(\.characterIndex) == [0, 8, 15])
    #expect(Set(entries.map(\.object.identifier)).count == 3)
    let first = try paragraphStyle(entries[0].object.identifier, in: surgeon)
    #expect(first.paraProperties.leftIndent == 10)
    // .indent(left) defaults the absolute first-line indent to left.
    #expect(first.paraProperties.firstLineIndent == 10)
    let second = try paragraphStyle(entries[1].object.identifier, in: surgeon)
    #expect(second.paraProperties.leftIndent == 20)
    #expect(second.paraProperties.firstLineIndent == 30)
    let third = try paragraphStyle(entries[2].object.identifier, in: surgeon)
    #expect(third.paraProperties.alignment == .tatvalue1)
    let references = storage.record.info.messageInfos[0].objectReferences
    for entry in entries {
      #expect(references.contains(entry.object.identifier))
    }
  }

  @Test("identical formats share a fork and collapse adjacent entries")
  internal func dedupeCollapsesEntries() throws {
    let surgeon = try written(
      Deck {
        Slide {
          TextBox {
            Paragraph("a").alignment(.center)
            Paragraph("b").alignment(.center)
            Paragraph("c")
          }
          .textAlignment(.left)
        }
      }
    )
    let storage = try firstStorage(in: surgeon)
    let entries = storage.archive.tableParaStyle.entries
    try #require(entries.count == 2)
    #expect(entries[0].characterIndex == 0)
    #expect(entries[1].characterIndex == 4)
    #expect(entries[0].object.identifier != entries[1].object.identifier)
  }

  @Test("run offsets account for paragraph separators")
  internal func runOffsetsCrossParagraphs() throws {
    let surgeon = try written(
      Deck {
        Slide {
          TextBox {
            Text("plain")
            Paragraph {
              Text("bold").bold()
              Text(" rest")
            }
          }
        }
      }
    )
    let storage = try firstStorage(in: surgeon)
    let entries = storage.archive.tableCharStyle.entries
    try #require(entries.count == 3)
    // "plain" (5) + "\n" → the second paragraph's spans start at 6.
    #expect(entries.map(\.characterIndex) == [0, 6, 10])
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
