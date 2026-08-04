import Foundation
import IWAFraming
import KeynoteKit
import KeynoteKitProtobuf
import Testing

@Suite("TextBox runs")
internal struct TextRunTests {
  @Test("writes per-run character styles onto tableCharStyle")
  internal func writesRuns() throws {
    let surgeon = try written(
      Deck {
        Slide {
          TextBox {
            Paragraph {
              Text("Styled")
                .bold()
                .fontSize(48)
                .foregroundColor(Color(red: 0.9, green: 0.1, blue: 0.1))
              Text(" plain")
            }
          }
          TextBox("Neighbor")
        }
      }
    )
    let archive = try firstSlideArchive(in: surgeon)
    let storage = try storage(forDrawable: archive.drawablesZOrder[0].identifier, in: surgeon)
    #expect(storage.text == ["Styled plain"])
    try #require(storage.tableCharStyle.entries.count == 2)
    let styled = storage.tableCharStyle.entries[0]
    let plain = storage.tableCharStyle.entries[1]
    #expect(styled.characterIndex == 0)
    #expect(plain.characterIndex == 6)
    #expect(styled.object.identifier != 0)
    #expect(plain.object.identifier != 0)
    #expect(styled.object.identifier != plain.object.identifier)

    let styledStyle = try characterStyle(styled.object.identifier, in: surgeon)
    #expect(styledStyle.charProperties.bold == true)
    #expect(styledStyle.charProperties.fontSize == 48)
    #expect(styledStyle.charProperties.hasTsdFill)
    #expect(abs(styledStyle.charProperties.tsdFill.color.r - 0.9) < 0.001)
    #expect(styledStyle.overrideCount == 4)
    #expect(styledStyle.super.hasStylesheet)

    let plainStyle = try characterStyle(plain.object.identifier, in: surgeon)
    #expect(plainStyle.overrideCount == 0)
    #expect(!plainStyle.charProperties.hasBold)

    try expectRegistered(
      [styled.object.identifier, plain.object.identifier],
      onStorageOf: archive.drawablesZOrder[0].identifier,
      in: surgeon
    )

    let neighbor = try self.storage(
      forDrawable: archive.drawablesZOrder[1].identifier,
      in: surgeon
    )
    #expect(neighbor.tableCharStyle.entries.isEmpty)
  }

  @Test("run-level italic and font lower onto the character style")
  internal func italicAndFontRuns() throws {
    let surgeon = try written(
      Deck {
        Slide {
          TextBox {
            Paragraph {
              Text("Slanted").italic().font("Helvetica")
              Text(" upright")
            }
          }
          TextBox("Neighbor")
        }
      }
    )
    let archive = try firstSlideArchive(in: surgeon)
    let storage = try storage(forDrawable: archive.drawablesZOrder[0].identifier, in: surgeon)
    try #require(storage.tableCharStyle.entries.count == 2)
    let slanted = try characterStyle(
      storage.tableCharStyle.entries[0].object.identifier,
      in: surgeon
    )
    #expect(slanted.charProperties.italic == true)
    #expect(slanted.charProperties.fontName == "Helvetica")
    #expect(!slanted.charProperties.hasBold)
  }

  @Test("all-plain runs write no character styles")
  internal func plainRuns() throws {
    let surgeon = try written(
      Deck {
        Slide {
          TextBox {
            Paragraph {
              Text("Two ")
              Text("plain spans")
            }
          }
          TextBox("Neighbor")
        }
      }
    )
    let archive = try firstSlideArchive(in: surgeon)
    let storage = try storage(forDrawable: archive.drawablesZOrder[0].identifier, in: surgeon)
    #expect(storage.text == ["Two plain spans"])
    #expect(storage.tableCharStyle.entries.isEmpty)
  }

  @Test("item-wide formatting composes with run overrides")
  internal func itemAndRunFormatting() throws {
    let surgeon = try written(
      Deck {
        Slide {
          TextBox {
            Paragraph {
              Text("Red").foregroundColor(Color(red: 1, green: 0, blue: 0))
              Text(" default")
            }
          }
          .fontSize(30)
          TextBox("Neighbor")
        }
      }
    )
    let archive = try firstSlideArchive(in: surgeon)
    let storage = try storage(forDrawable: archive.drawablesZOrder[0].identifier, in: surgeon)
    let fork = try paragraphStyle(
      storage.tableParaStyle.entries[0].object.identifier,
      in: surgeon
    )
    #expect(fork.super.isVariation)
    #expect(fork.charProperties.fontSize == 30)
    try #require(storage.tableCharStyle.entries.count == 2)
    let red = try characterStyle(
      storage.tableCharStyle.entries[0].object.identifier,
      in: surgeon
    )
    #expect(red.charProperties.hasTsdFill)
    #expect(!red.charProperties.hasFontSize)
  }

  /// Writes the deck and reopens it as a surgeon.
  private func written(_ deck: Deck) throws -> KeynoteArchiveSurgeon {
    let url = FileManager.default.temporaryDirectory
      .appending(path: "runs-\(UUID().uuidString).key")
    defer { try? FileManager.default.removeItem(at: url) }
    try deck.write(to: url)
    return try KeynoteArchiveSurgeon(
      bundle: try KeyBundle(contentsOfZip: Array(try Data(contentsOf: url)))
    )
  }

  /// Asserts each minted style is on the storage record header's references
  /// and the document stylesheet's `styles` list — the edges Keynote needs
  /// to resolve and apply the style.
  private func expectRegistered(
    _ identifiers: [UInt64],
    onStorageOf drawableIdentifier: UInt64,
    in surgeon: KeynoteArchiveSurgeon
  ) throws {
    let catalog = SlideCatalog(members: surgeon.members)
    let shape = try placeholder(forDrawable: drawableIdentifier, in: surgeon)
    let storageLocation = try #require(
      try catalog.locate(
        recordIdentifier: shape.super.ownedStorage.identifier,
        named: "TSWP.StorageArchive"
      )
    )
    let references = surgeon.members[storageLocation.memberIndex]
      .records[storageLocation.recordIndex]
      .info.messageInfos[0].objectReferences
    let sheetLocation = try #require(try catalog.locateFirst(named: "TSS.StylesheetArchive"))
    let sheet = try TSS_StylesheetArchive(
      serializedBytes: surgeon.members[sheetLocation.memberIndex]
        .records[sheetLocation.recordIndex]
        .payloads[sheetLocation.payloadIndex],
      partial: true
    )
    for identifier in identifiers {
      #expect(references.contains(identifier))
      #expect(sheet.styles.contains { $0.identifier == identifier })
    }
  }
}
