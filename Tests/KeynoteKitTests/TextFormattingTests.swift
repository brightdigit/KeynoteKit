import Foundation
import IWAFraming
import KeynoteKit
import KeynoteKitProtobuf
import Testing

/// Text formatting (#37): authored style lands on a per-item character
/// style run, not the shared Body paragraph style.
@Suite("Text formatting")
internal struct TextFormattingTests {
  @Test("writes font, weight, and color onto a forked character style")
  internal func writesFormatting() throws {
    let deck = Deck {
      Slide {
        Text("Styled")
          .font("HelveticaNeue", size: 36)
          .bold()
          .italic()
          .foregroundColor(TextColor(red: 0.1, green: 0.2, blue: 0.8))
        Text("Plain")
      }
    }
    let url = FileManager.default.temporaryDirectory
      .appending(path: "format-\(UUID().uuidString).key")
    defer { try? FileManager.default.removeItem(at: url) }
    try deck.write(to: url)

    let surgeon = try KeynoteArchiveSurgeon(
      bundle: try KeyBundle(contentsOfZip: Array(try Data(contentsOf: url)))
    )
    let catalog = SlideCatalog(members: surgeon.members)
    let slides = try catalog.orderedSlides()
    let slide = try #require(slides.first)
    let archive = try KN_SlideArchive(
      serializedBytes: surgeon.members[slide.memberIndex].records[slide.recordIndex].payloads[0],
      partial: true
    )

    let styled = try characterStyle(
      forDrawable: archive.drawablesZOrder[0].identifier,
      in: surgeon
    )
    #expect(styled.bold == true)
    #expect(styled.italic == true)
    #expect(styled.fontSize == 36)
    #expect(styled.fontName == "HelveticaNeue")
    #expect(styled.hasFontColor)
    #expect(abs(styled.fontColor.r - 0.1) < 0.001)
    #expect(abs(styled.fontColor.g - 0.2) < 0.001)
    #expect(abs(styled.fontColor.b - 0.8) < 0.001)

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
    #expect(styledStorage.tableParaStyle.entries[0].object.identifier == bodyStyleId)
    #expect(styledStorage.tableCharStyle.entries.count == 1)
    #expect(styledStorage.tableCharStyle.entries[0].object.identifier != bodyStyleId)
  }

  private func storage(
    forDrawable identifier: UInt64,
    in surgeon: KeynoteArchiveSurgeon
  ) throws -> TSWP_StorageArchive {
    let catalog = SlideCatalog(members: surgeon.members)
    guard
      let placeholderLocation = try catalog.locate(
        recordIdentifier: identifier,
        named: "KN.PlaceholderArchive"
      )
    else {
      throw ArchiveSurgeryError.missingSlideRecord(identifier: identifier)
    }
    let placeholder = try KN_PlaceholderArchive(
      serializedBytes: surgeon.members[placeholderLocation.memberIndex]
        .records[placeholderLocation.recordIndex]
        .payloads[placeholderLocation.payloadIndex],
      partial: true
    )
    guard
      let storageLocation = try catalog.locate(
        recordIdentifier: placeholder.super.ownedStorage.identifier,
        named: "TSWP.StorageArchive"
      )
    else {
      throw ArchiveSurgeryError.missingSlideRecord(
        identifier: placeholder.super.ownedStorage.identifier
      )
    }
    return try TSWP_StorageArchive(
      serializedBytes: surgeon.members[storageLocation.memberIndex]
        .records[storageLocation.recordIndex]
        .payloads[storageLocation.payloadIndex],
      partial: true
    )
  }

  private func characterStyle(
    forDrawable identifier: UInt64,
    in surgeon: KeynoteArchiveSurgeon
  ) throws -> TSWP_CharacterStylePropertiesArchive {
    let catalog = SlideCatalog(members: surgeon.members)
    let storageArchive = try storage(forDrawable: identifier, in: surgeon)
    let styleId = try #require(storageArchive.tableCharStyle.entries.first).object.identifier
    guard
      let styleLocation = try catalog.locate(
        recordIdentifier: styleId,
        named: "TSWP.CharacterStyleArchive"
      )
    else {
      throw ArchiveSurgeryError.missingSlideRecord(identifier: styleId)
    }
    let style = try TSWP_CharacterStyleArchive(
      serializedBytes: surgeon.members[styleLocation.memberIndex]
        .records[styleLocation.recordIndex]
        .payloads[styleLocation.payloadIndex],
      partial: true
    )
    return style.charProperties
  }
}
