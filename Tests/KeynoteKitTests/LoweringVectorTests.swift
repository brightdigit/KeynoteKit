import Foundation
import IWAFraming
import KeynoteKitProtobuf
import Testing

@testable import KeynoteKit

/// Known-answer vectors for lowerings that were previously verified only by
/// the human Keynote pass: trigger ordinals, chunk automation, delays, and
/// custom motion-path points — plus the SHA-1 check value the digest tests
/// otherwise only compare against itself.
@Suite("Lowering vectors")
internal struct LoweringVectorTests {
  @Test("SHA-1 matches the FIPS 180-4 check value for \"abc\"")
  internal func sha1MatchesCheckValue() {
    let digest = SHA1Digest.hash(Array("abc".utf8))
    let hex = digest.map { String(format: "%02x", $0) }.joined()
    #expect(hex == "a9993e364706816aba3e25717850c26c9cd0d89d")
  }

  @Test(
    "triggers lower to their archive ordinals and chunk automation",
    arguments: [
      (AuthoredBuild.Trigger.onClick, UInt32(1), false),
      (AuthoredBuild.Trigger.afterPrevious, UInt32(2), true),
      (AuthoredBuild.Trigger.withPrevious, UInt32(3), true),
    ]
  )
  internal func triggersLower(
    trigger: AuthoredBuild.Trigger,
    ordinal: UInt32,
    automatic: Bool
  ) throws {
    let mint = try mintBuild(
      AuthoredBuild(
        kind: .buildIn,
        effect: "apple:dissolve character",
        targetIndex: 0,
        trigger: trigger
      )
    )
    #expect(mint.build.attributes.eventTrigger == ordinal)
    #expect(mint.chunk.automatic == automatic)
  }

  @Test("build delay lands on the animation attributes")
  internal func buildDelayLowers() throws {
    let mint = try mintBuild(
      AuthoredBuild(
        kind: .buildIn,
        effect: "apple:dissolve character",
        delay: 2.5,
        targetIndex: 0
      )
    )
    #expect(mint.build.attributes.animationAttributes.delay == 2.5)
  }

  @Test("custom motion-path points survive into the bezier source")
  internal func motionPathPointsLower() throws {
    let path = AuthoredMotionPath(
      naturalWidth: 400,
      naturalHeight: 300,
      points: [
        AuthoredMotionPath.Point(x: 0, y: 0),
        AuthoredMotionPath.Point(x: 150, y: 60),
        AuthoredMotionPath.Point(x: 400, y: 300),
      ]
    )
    let mint = try mintBuild(
      AuthoredBuild(
        kind: .action,
        effect: "apple:action-motion-path",
        targetIndex: 0,
        motionPath: path
      )
    )
    let bezier = mint.build.attributes.actionMotionPathSource.editableBezierPathSource
    #expect(bezier.naturalSize.width == 400)
    #expect(bezier.naturalSize.height == 300)
    let nodes = try #require(bezier.subpaths.first?.nodes)
    #expect(nodes.map(\.nodePoint.x) == [0, 150, 400])
    #expect(nodes.map(\.nodePoint.y) == [0, 60, 300])
  }

  @Test("transition delay and autoAdvance lower onto the slide archive")
  internal func transitionDelayAndAutoAdvanceLower() throws {
    let deck = Deck {
      Slide { TextBox("only") }
        .transition(.dissolve.duration(2).delay(0.75).autoAdvance(true))
    }
    let url = FileManager.default.temporaryDirectory
      .appending(path: "lowering-\(UUID().uuidString).key")
    defer { try? FileManager.default.removeItem(at: url) }
    try deck.write(to: url)

    let bundle = try KeyBundle(contentsOfZip: Array(try Data(contentsOf: url)))
    let surgeon = try KeynoteArchiveSurgeon(bundle: bundle)
    let slide = try #require(try SlideCatalog(members: surgeon.members).orderedSlides().first)
    let archive = try KN_SlideArchive(
      serializedBytes: surgeon.members[slide.memberIndex]
        .records[slide.recordIndex]
        .payloads[0],
      partial: true
    )
    let animation = archive.transition.attributes.animationAttributes
    #expect(animation.duration == 2)
    #expect(animation.delay == 0.75)
    #expect(animation.isAutomatic)
  }

  @Test("SlideBuilder lowers if/else and for slides in declaration order")
  internal func slideBuilderControlFlowLowers() throws {
    let includeExtra = true
    let deck = Deck {
      if includeExtra {
        Slide { TextBox("first") }
      } else {
        Slide { TextBox("wrong branch") }
      }
      for label in ["second", "third"] {
        Slide { TextBox(label) }
      }
      if !includeExtra {
        Slide { TextBox("absent") }
      }
    }
    let authored = try deck.authoredDeck()
    #expect(authored.slides.count == 3)
  }

  @Test("an empty deck writes a parseable copy of the template")
  internal func emptyDeckWritesParseableTemplate() throws {
    let url = FileManager.default.temporaryDirectory
      .appending(path: "empty-\(UUID().uuidString).key")
    defer { try? FileManager.default.removeItem(at: url) }
    try Deck {}.write(to: url)
    let bundle = try KeyBundle(contentsOfZip: Array(try Data(contentsOf: url)))
    let surgeon = try KeynoteArchiveSurgeon(bundle: bundle)
    let slides = try SlideCatalog(members: surgeon.members).orderedSlides()
    #expect(slides.count == 1)
  }

  /// Mints one build and decodes both archives.
  private func mintBuild(
    _ build: AuthoredBuild
  ) throws -> (build: KN_BuildArchive, chunk: KN_BuildChunkArchive) {
    var generator = SystemRandomNumberGenerator()
    let mint = try BuildRecordFactory.mint(
      build,
      drawableIdentifier: 50,
      buildIdentifier: 100,
      chunkIdentifier: 101,
      using: &generator
    )
    return (
      build: try KN_BuildArchive(serializedBytes: mint.buildRecord.payloads[0], partial: true),
      chunk: try KN_BuildChunkArchive(serializedBytes: mint.chunkRecord.payloads[0], partial: true)
    )
  }
}
