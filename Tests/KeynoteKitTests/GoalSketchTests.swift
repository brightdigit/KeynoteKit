import Foundation
import IWAFraming
import KeynoteKit
import KeynoteKitProtobuf
import Testing

/// The #23 gate: the PLAN Goal sketch compiles as written and produces a
/// structurally valid deck — every record decodes, both invariants hold,
/// and the authored builds and transition are present.
@Suite("Goal sketch")
internal struct GoalSketchTests {
  /// The PLAN Goal sketch, verbatim in shape.
  private struct TitleSlide: SlideContent {
    var body: some SlideContent {
      Slide {
        Text("Title")
          .magicId("title")
          .position(x: 200, y: 200)
          .build(.in) {
            Dissolve()
              .duration(1)
              .trigger(.onClick)
          }
          .action {
            MotionPath()
              .duration(1)
              .trigger(.afterPrevious)
          }
      }
      .transition(.magicMove.duration(1))
    }
  }

  /// The direction-carrying transition of the acceptance shape.
  private var directionTransition: SlideTransition {
    SlideTransition.moveIn
      .duration(1)
      .delay(0.5)
      .direction(.moveInNonDefault)
  }

  @Test("the Goal sketch compiles and writes a structurally valid deck")
  internal func goalSketchWrites() throws {
    let deck = Deck {
      TitleSlide()
    }
    let url = FileManager.default.temporaryDirectory
      .appending(path: "goal-sketch-\(UUID().uuidString).key")
    defer { try? FileManager.default.removeItem(at: url) }
    try deck.write(to: url)

    let bundle = try KeyBundle(contentsOfZip: Array(try Data(contentsOf: url)))
    let surgeon = try KeynoteArchiveSurgeon(bundle: bundle)
    for member in surgeon.members {
      for record in member.records {
        _ = try record.decodedMessages()
      }
    }
    try UUIDMapVerifier.verify(members: surgeon.members, expectedBuildCount: 2)

    let slides = try SlideCatalog(members: surgeon.members).orderedSlides()
    let slide = try #require(slides.first)
    let archive = try KN_SlideArchive(
      serializedBytes: surgeon.members[slide.memberIndex].records[slide.recordIndex].payloads[0],
      partial: true
    )
    #expect(archive.builds.count == 2)
    let transition = archive.transition.attributes.animationAttributes
    #expect(transition.effect == "apple:magic-move-implied-motion-path")
    #expect(transition.duration == 1.0)
  }

  @Test("a multi-slide deck with direction and out builds writes")
  internal func acceptanceShapedDeckWrites() throws {
    let deck = Deck {
      Slide {
        Text("Build In").position(x: 200, y: 180)
          .build(.in) { Dissolve() }
        Text("Build Out").position(x: 200, y: 360)
          .build(.out) { Dissolve() }
        Text("Action").position(x: 200, y: 540)
          .action { MotionPath() }
      }
      Slide {
        Text("Direction")
      }
      .transition(directionTransition)
    }
    let url = FileManager.default.temporaryDirectory
      .appending(path: "acceptance-shape-\(UUID().uuidString).key")
    defer { try? FileManager.default.removeItem(at: url) }
    try deck.write(to: url)

    let bundle = try KeyBundle(contentsOfZip: Array(try Data(contentsOf: url)))
    let surgeon = try KeynoteArchiveSurgeon(bundle: bundle)
    try UUIDMapVerifier.verify(members: surgeon.members, expectedBuildCount: 3)
    let slides = try SlideCatalog(members: surgeon.members).orderedSlides()
    #expect(slides.count == 2)
    let records = surgeon.members[slides[1].memberIndex].records
    let second = try KN_SlideArchive(
      serializedBytes: records[slides[1].recordIndex].payloads[0],
      partial: true
    )
    #expect(second.transition.attributes.animationAttributes.direction == 11)
    #expect(second.transition.attributes.animationAttributes.effect == "apple:slide")
  }
}
