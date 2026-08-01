import Foundation
import IWAFraming
import KeynoteKit
import KeynoteKitProtobuf
import Testing

/// Rotation (#51 step 3): `rotationEffect` writes `geometry.angle` — the
/// archive field is counterclockwise-positive degrees
/// (`research/findings/drawable_geometry.md`), the DSL SwiftUI-style
/// clockwise-positive, so authored values negate on write.
@Suite("TextBox rotation")
internal struct RotationTests {
  @Test("rotationEffect writes negated degrees and the sized-drawable flags")
  internal func rotationWritesAngle() throws {
    let geometry = try authoredGeometry(
      of: TextBox("Tilted").position(x: 100, y: 120).rotationEffect(.degrees(45))
    )
    #expect(geometry.angle == -45)
    #expect(geometry.flags == 3)
  }

  @Test("radians convert to degrees on write")
  internal func rotationConvertsRadians() throws {
    let geometry = try authoredGeometry(
      of: TextBox("Quarter").rotationEffect(.radians(.pi / 2))
    )
    #expect(abs(geometry.angle - (-90)) < 0.001)
  }

  @Test("unrotated boxes keep the template's zero angle")
  internal func unrotatedKeepsTemplateAngle() throws {
    // The template placeholder carries an explicit angle of 0; byte
    // stability of unrotated decks is guarded by the golden differential.
    let geometry = try authoredGeometry(
      of: TextBox("Level").position(x: 100, y: 120)
    )
    #expect(geometry.angle == 0)
  }

  /// Authors a one-box deck and returns the box's placeholder geometry.
  private func authoredGeometry(of box: TextBox) throws -> TSD_GeometryArchive {
    let url = FileManager.default.temporaryDirectory
      .appending(path: "rotation-\(UUID().uuidString).key")
    defer { try? FileManager.default.removeItem(at: url) }
    try Deck {
      Slide {
        box
      }
    }
    .write(to: url)
    let bundle = try KeyBundle(contentsOfZip: Array(try Data(contentsOf: url)))
    let surgeon = try KeynoteArchiveSurgeon(bundle: bundle)
    let catalog = SlideCatalog(members: surgeon.members)
    let slide = try #require(try catalog.orderedSlides().first)
    let archive = try KN_SlideArchive(
      serializedBytes: surgeon.members[slide.memberIndex].records[slide.recordIndex].payloads[0],
      partial: true
    )
    let drawableIdentifier = try #require(archive.drawablesZOrder.first).identifier
    let location = try #require(
      try catalog.locate(recordIdentifier: drawableIdentifier, named: "KN.PlaceholderArchive")
    )
    let placeholder = try KN_PlaceholderArchive(
      serializedBytes: surgeon.members[location.memberIndex]
        .records[location.recordIndex]
        .payloads[location.payloadIndex],
      partial: true
    )
    return placeholder.super.super.super.geometry
  }
}
