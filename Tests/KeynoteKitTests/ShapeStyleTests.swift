import Foundation
import IWAFraming
import KeynoteKit
import KeynoteKitProtobuf
import Testing

/// Vertical alignment + columns (#51 step 5): either setting mints one
/// type-2025 variation of the placeholder's style, repoints
/// `TSD.ShapeArchive.style`, and registers every edge. The column gap is a
/// fraction of the layout master's body width
/// (`research/findings/text_columns.md`).
@Suite("Shape style forks")
internal struct ShapeStyleTests {
  @Test("verticalAlignment mints a variation and repoints the shape style")
  internal func verticalAlignmentForks() throws {
    let surgeon = try written(
      Deck {
        Slide {
          TextBox("Bottom").verticalAlignment(.bottom)
        }
      }
    )
    let fork = try referencedShapeStyle(in: surgeon)
    #expect(fork.archive.super.super.isVariation)
    #expect(fork.archive.shapeProperties.verticalAlignment == .kFrameAlignBottom)
    #expect(fork.archive.overrideCount == 1)
    #expect(fork.archive.super.overrideCount == 1)
    #expect(fork.archive.super.hasShapeProperties)
    try expectRegistered(fork.identifier, in: surgeon)
  }

  @Test("columns write count and the gap as a fraction of the master width")
  internal func columnsWriteCountAndGap() throws {
    let surgeon = try written(
      Deck {
        Slide {
          // 41.25pt over the blank template's 825pt master body = 0.05,
          // the value Keynote itself wrote in build_action_B.key.
          TextBox("Columns").columns(2, gap: 41.25)
        }
      }
    )
    let fork = try referencedShapeStyle(in: surgeon)
    let columns = fork.archive.shapeProperties.columns.equalColumns
    #expect(columns.count == 2)
    #expect(abs(columns.gap - 0.05) < 0.0001)
  }

  @Test("columns without a gap inherit the template gutter")
  internal func columnsWithoutGap() throws {
    let surgeon = try written(
      Deck {
        Slide {
          TextBox("Columns").columns(3)
        }
      }
    )
    let fork = try referencedShapeStyle(in: surgeon)
    let columns = fork.archive.shapeProperties.columns.equalColumns
    #expect(columns.count == 3)
    #expect(!columns.hasGap)
  }

  @Test("boxes without either setting keep the template shape style")
  internal func unsetKeepsTemplateStyle() throws {
    let baseline = try written(
      Deck {
        Slide {
          TextBox("Bare")
        }
      }
    )
    let surgeon = try written(
      Deck {
        Slide {
          TextBox("Plain").textAlignment(.center)
        }
      }
    )
    let baselineStyle = try firstPlaceholder(in: baseline).super.super.style.identifier
    let unsetStyle = try firstPlaceholder(in: surgeon).super.super.style.identifier
    #expect(unsetStyle == baselineStyle)
  }

  /// Writes the deck and reopens it as a surgeon.
  private func written(_ deck: Deck) throws -> KeynoteArchiveSurgeon {
    let url = FileManager.default.temporaryDirectory
      .appending(path: "shapestyle-\(UUID().uuidString).key")
    defer { try? FileManager.default.removeItem(at: url) }
    try deck.write(to: url)
    return try KeynoteArchiveSurgeon(
      bundle: try KeyBundle(contentsOfZip: Array(try Data(contentsOf: url)))
    )
  }

  /// The first drawable's placeholder archive.
  private func firstPlaceholder(
    in surgeon: KeynoteArchiveSurgeon
  ) throws -> KN_PlaceholderArchive {
    let catalog = SlideCatalog(members: surgeon.members)
    let slide = try #require(try catalog.orderedSlides().first)
    let slideArchive = try KN_SlideArchive(
      serializedBytes: surgeon.members[slide.memberIndex].records[slide.recordIndex].payloads[0],
      partial: true
    )
    let drawableIdentifier = try #require(slideArchive.drawablesZOrder.first).identifier
    let location = try #require(
      try catalog.locate(recordIdentifier: drawableIdentifier, named: "KN.PlaceholderArchive")
    )
    return try KN_PlaceholderArchive(
      serializedBytes: surgeon.members[location.memberIndex]
        .records[location.recordIndex]
        .payloads[location.payloadIndex],
      partial: true
    )
  }

  /// The shape style referenced by the first drawable's placeholder, with
  /// the placeholder's header reference asserted along the way.
  private func referencedShapeStyle(
    in surgeon: KeynoteArchiveSurgeon
  ) throws -> (archive: TSWP_ShapeStyleArchive, identifier: UInt64) {
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
  private func expectRegistered(
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
}
