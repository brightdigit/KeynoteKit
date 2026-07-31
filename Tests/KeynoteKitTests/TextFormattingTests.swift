import Foundation
import IWAFraming
import KeynoteKit
import KeynoteKitProtobuf
import Testing

@Suite("TextBox formatting")
internal struct TextFormattingTests {
  @Test("writes font, weight, color, and geometry onto a forked paragraph style")
  internal func writesFormatting() throws {
    let deck = Deck {
      Slide {
        TextBox("Styled")
          .font("HelveticaNeue", size: 36)
          .bold()
          .italic()
          .foregroundColor(TextColor(red: 0.1, green: 0.2, blue: 0.8))
          .position(x: 160, y: 220)
          .frame(width: 480, height: 100)
        TextBox("Plain")
      }
    }
    let url = FileManager.default.temporaryDirectory
      .appending(path: "format-\(UUID().uuidString).key")
    defer { try? FileManager.default.removeItem(at: url) }
    try deck.write(to: url)

    let surgeon = try KeynoteArchiveSurgeon(
      bundle: try KeyBundle(contentsOfZip: Array(try Data(contentsOf: url)))
    )
    let archive = try firstSlideArchive(in: surgeon)

    let plainStorage = try storage(
      forDrawable: archive.drawablesZOrder[1].identifier,
      in: surgeon
    )
    #expect(plainStorage.tableCharStyle.entries.isEmpty)
    let bodyStyleId = plainStorage.tableParaStyle.entries[0].object.identifier

    let styledStorage = try storage(
      forDrawable: archive.drawablesZOrder[0].identifier,
      in: surgeon
    )
    #expect(styledStorage.tableCharStyle.entries.isEmpty)
    let forkId = styledStorage.tableParaStyle.entries[0].object.identifier
    #expect(forkId != bodyStyleId)

    let fork = try paragraphStyle(forkId, in: surgeon)
    #expect(fork.super.isVariation)
    #expect(fork.super.parent.identifier == bodyStyleId)
    expectForkProperties(fork.charProperties)

    let geometry = try placeholderGeometry(
      forDrawable: archive.drawablesZOrder[0].identifier,
      in: surgeon
    )
    #expect(geometry.position.x == 160)
    #expect(geometry.position.y == 220)
    #expect(geometry.size.width == 480)
    #expect(geometry.size.height == 100)
  }

  /// Asserts the fork carries the authored font, weight, and color (with the
  /// `tsdFill` Keynote actually paints glyphs with).
  private func expectForkProperties(_ properties: TSWP_CharacterStylePropertiesArchive) {
    #expect(properties.bold == true)
    #expect(properties.italic == true)
    #expect(properties.fontSize == 36)
    #expect(properties.fontName == "HelveticaNeue")
    #expect(properties.hasFontColor)
    #expect(abs(properties.fontColor.r - 0.1) < 0.001)
    #expect(abs(properties.fontColor.g - 0.2) < 0.001)
    #expect(abs(properties.fontColor.b - 0.8) < 0.001)
    #expect(properties.hasTsdFill)
    #expect(abs(properties.tsdFill.color.b - 0.8) < 0.001)
  }

  /// Decodes the first slide's `KN.SlideArchive`.
  private func firstSlideArchive(in surgeon: KeynoteArchiveSurgeon) throws -> KN_SlideArchive {
    let catalog = SlideCatalog(members: surgeon.members)
    let slide = try #require(try catalog.orderedSlides().first)
    return try KN_SlideArchive(
      serializedBytes: surgeon.members[slide.memberIndex].records[slide.recordIndex].payloads[0],
      partial: true
    )
  }

  private func placeholder(
    forDrawable identifier: UInt64,
    in surgeon: KeynoteArchiveSurgeon
  ) throws -> KN_PlaceholderArchive {
    let catalog = SlideCatalog(members: surgeon.members)
    guard
      let placeholderLocation = try catalog.locate(
        recordIdentifier: identifier,
        named: "KN.PlaceholderArchive"
      )
    else {
      throw ArchiveSurgeryError.missingSlideRecord(identifier: identifier)
    }
    return try KN_PlaceholderArchive(
      serializedBytes: surgeon.members[placeholderLocation.memberIndex]
        .records[placeholderLocation.recordIndex]
        .payloads[placeholderLocation.payloadIndex],
      partial: true
    )
  }

  private func placeholderGeometry(
    forDrawable identifier: UInt64,
    in surgeon: KeynoteArchiveSurgeon
  ) throws -> TSD_GeometryArchive {
    try placeholder(forDrawable: identifier, in: surgeon).super.super.super.geometry
  }

  private func storage(
    forDrawable identifier: UInt64,
    in surgeon: KeynoteArchiveSurgeon
  ) throws -> TSWP_StorageArchive {
    let catalog = SlideCatalog(members: surgeon.members)
    let shape = try placeholder(forDrawable: identifier, in: surgeon)
    guard
      let storageLocation = try catalog.locate(
        recordIdentifier: shape.super.ownedStorage.identifier,
        named: "TSWP.StorageArchive"
      )
    else {
      throw ArchiveSurgeryError.missingSlideRecord(
        identifier: shape.super.ownedStorage.identifier
      )
    }
    return try TSWP_StorageArchive(
      serializedBytes: surgeon.members[storageLocation.memberIndex]
        .records[storageLocation.recordIndex]
        .payloads[storageLocation.payloadIndex],
      partial: true
    )
  }

  private func paragraphStyle(
    _ identifier: UInt64,
    in surgeon: KeynoteArchiveSurgeon
  ) throws -> TSWP_ParagraphStyleArchive {
    let catalog = SlideCatalog(members: surgeon.members)
    guard
      let styleLocation = try catalog.locate(
        recordIdentifier: identifier,
        named: "TSWP.ParagraphStyleArchive"
      )
    else {
      throw ArchiveSurgeryError.missingSlideRecord(identifier: identifier)
    }
    return try TSWP_ParagraphStyleArchive(
      serializedBytes: surgeon.members[styleLocation.memberIndex]
        .records[styleLocation.recordIndex]
        .payloads[styleLocation.payloadIndex],
      partial: true
    )
  }
}
