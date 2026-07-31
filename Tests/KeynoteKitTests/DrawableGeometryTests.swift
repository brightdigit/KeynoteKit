import Foundation
import IWAFraming
import KeynoteKit
import KeynoteKitProtobuf
import Testing

/// Geometry (#3): authored width/height land on drawable geometry; z-index
/// reorders `drawablesZOrder` and keeps build `targetIndex` aligned.
@Suite("Drawable geometry")
internal struct DrawableGeometryTests {
  @Test("writes authored frame size onto placeholder geometry")
  internal func writesFrameSize() throws {
    let deck = Deck {
      Slide {
        TextBox("Sized")
          .position(x: 100, y: 120)
          .frame(width: 400, height: 80)
      }
    }
    let surgeon = try authorSurgeon(from: deck)
    let geometry = try firstPlaceholderGeometry(in: surgeon)
    #expect(geometry.position.x == 100)
    #expect(geometry.position.y == 120)
    #expect(geometry.size.width == 400)
    #expect(geometry.size.height == 80)
  }

  @Test("leaves template size when frame is unset")
  internal func leavesTemplateSizeWhenUnset() throws {
    let deck = Deck {
      Slide {
        TextBox("Default size").position(x: 50, y: 60)
      }
    }
    let baseline = try authorSurgeon(
      from: Deck {
        Slide {
          TextBox("probe")
        }
      }
    )
    let baselineSize = try firstPlaceholderGeometry(in: baseline).size
    let surgeon = try authorSurgeon(from: deck)
    let geometry = try firstPlaceholderGeometry(in: surgeon)
    #expect(geometry.position.x == 50)
    #expect(geometry.position.y == 60)
    #expect(geometry.size.width == baselineSize.width)
    #expect(geometry.size.height == baselineSize.height)
  }

  @Test("zIndex reorders drawables and aligns build targets")
  internal func zIndexReordersDrawables() throws {
    let deck = Deck {
      Slide {
        TextBox("Bottom")
          .zIndex(0)
          .build(.in) { Dissolve() }
        TextBox("Top")
          .zIndex(10)
          .build(.out) { Dissolve() }
        TextBox("Middle")
          .zIndex(5)
      }
    }
    let url = FileManager.default.temporaryDirectory
      .appending(path: "zindex-\(UUID().uuidString).key")
    defer { try? FileManager.default.removeItem(at: url) }
    try deck.write(to: url)

    let bundle = try KeyBundle(contentsOfZip: Array(try Data(contentsOf: url)))
    let surgeon = try KeynoteArchiveSurgeon(bundle: bundle)
    let slides = try SlideCatalog(members: surgeon.members).orderedSlides()
    let slide = try #require(slides.first)
    let archive = try KN_SlideArchive(
      serializedBytes: surgeon.members[slide.memberIndex].records[slide.recordIndex].payloads[0],
      partial: true
    )
    #expect(archive.drawablesZOrder.count == 3)

    let texts = try archive.drawablesZOrder.map { reference in
      try storageText(forDrawable: reference.identifier, in: surgeon)
    }
    #expect(texts == ["Bottom", "Middle", "Top"])

    #expect(archive.builds.count == 2)
    let catalog = SlideCatalog(members: surgeon.members)
    let bottomId = archive.drawablesZOrder[0].identifier
    let topId = archive.drawablesZOrder[2].identifier
    let inBuild = try loadBuild(archive.builds[0].identifier, in: surgeon)
    let outBuild = try loadBuild(archive.builds[1].identifier, in: surgeon)
    #expect(inBuild.drawable.identifier == bottomId)
    #expect(outBuild.drawable.identifier == topId)
    #expect(catalog.locate(recordIdentifier: bottomId) != nil)
    #expect(catalog.locate(recordIdentifier: topId) != nil)
  }

  /// Authors `deck` and returns a surgeon over the result.
  private func authorSurgeon(from deck: Deck) throws -> KeynoteArchiveSurgeon {
    let url = FileManager.default.temporaryDirectory
      .appending(path: "geometry-\(UUID().uuidString).key")
    defer { try? FileManager.default.removeItem(at: url) }
    try deck.write(to: url)
    let bundle = try KeyBundle(contentsOfZip: Array(try Data(contentsOf: url)))
    return try KeynoteArchiveSurgeon(bundle: bundle)
  }

  /// Geometry of the first drawable on the first slide.
  private func firstPlaceholderGeometry(
    in surgeon: KeynoteArchiveSurgeon
  ) throws -> TSD_GeometryArchive {
    let slides = try SlideCatalog(members: surgeon.members).orderedSlides()
    let slide = try #require(slides.first)
    let archive = try KN_SlideArchive(
      serializedBytes: surgeon.members[slide.memberIndex].records[slide.recordIndex].payloads[0],
      partial: true
    )
    let drawableId = try #require(archive.drawablesZOrder.first).identifier
    return try placeholderGeometry(for: drawableId, in: surgeon)
  }

  /// Placeholder geometry for a drawable id.
  private func placeholderGeometry(
    for identifier: UInt64,
    in surgeon: KeynoteArchiveSurgeon
  ) throws -> TSD_GeometryArchive {
    let catalog = SlideCatalog(members: surgeon.members)
    guard
      let location = try catalog.locate(
        recordIdentifier: identifier,
        named: "KN.PlaceholderArchive"
      )
    else {
      Issue.record("missing placeholder \(identifier)")
      throw ArchiveSurgeryError.missingSlideRecord(identifier: identifier)
    }
    let placeholder = try KN_PlaceholderArchive(
      serializedBytes: surgeon.members[location.memberIndex]
        .records[location.recordIndex]
        .payloads[location.payloadIndex],
      partial: true
    )
    return placeholder.super.super.super.geometry
  }

  /// Reads the storage text for a drawable placeholder.
  private func storageText(
    forDrawable identifier: UInt64,
    in surgeon: KeynoteArchiveSurgeon
  ) throws -> String {
    let catalog = SlideCatalog(members: surgeon.members)
    guard
      let location = try catalog.locate(
        recordIdentifier: identifier,
        named: "KN.PlaceholderArchive"
      )
    else {
      Issue.record("missing placeholder \(identifier)")
      throw ArchiveSurgeryError.missingSlideRecord(identifier: identifier)
    }
    let placeholder = try KN_PlaceholderArchive(
      serializedBytes: surgeon.members[location.memberIndex]
        .records[location.recordIndex]
        .payloads[location.payloadIndex],
      partial: true
    )
    guard
      let storageLocation = try catalog.locate(
        recordIdentifier: placeholder.super.ownedStorage.identifier,
        named: "TSWP.StorageArchive"
      )
    else {
      Issue.record("missing storage")
      throw ArchiveSurgeryError.missingSlideRecord(
        identifier: placeholder.super.ownedStorage.identifier
      )
    }
    let storage = try TSWP_StorageArchive(
      serializedBytes: surgeon.members[storageLocation.memberIndex]
        .records[storageLocation.recordIndex]
        .payloads[storageLocation.payloadIndex],
      partial: true
    )
    return storage.text.joined()
  }

  /// Loads a `KN.BuildArchive` by record id.
  private func loadBuild(
    _ identifier: UInt64,
    in surgeon: KeynoteArchiveSurgeon
  ) throws -> KN_BuildArchive {
    let catalog = SlideCatalog(members: surgeon.members)
    guard
      let location = try catalog.locate(
        recordIdentifier: identifier,
        named: "KN.BuildArchive"
      )
    else {
      Issue.record("missing build \(identifier)")
      throw ArchiveSurgeryError.missingSlideRecord(identifier: identifier)
    }
    return try KN_BuildArchive(
      serializedBytes: surgeon.members[location.memberIndex]
        .records[location.recordIndex]
        .payloads[location.payloadIndex],
      partial: true
    )
  }
}
