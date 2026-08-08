import Foundation
import IWAFraming
import KeynoteKitProtobuf
import Testing

@testable import KeynoteKit

/// Flexible frames: `.frame(maxWidth:maxHeight:)` lets a drawable expand
/// into the bounds its parent proposes, so a slide can be filled with
/// margins without the author restating the canvas size.
@Suite("Flexible frames")
internal struct FlexibleFrameTests {
  /// `.frame(maxWidth: .infinity)` is what lets a box span the slide
  /// without the author restating the canvas width — the padded canvas is
  /// 1920 - 80*2 = 1760 wide.
  @Test("a filling leaf adopts the padded canvas width")
  internal func fillingLeafAdoptsPaddedCanvas() {
    let slide = Slide {
      VStack {
        TextBox("fills").frame(maxWidth: .infinity, height: 120)
      }
      .padding(80)
    }
    #expect(positions(of: slide) == [LayoutPoint(x: 80, y: 80)])
    #expect(sizes(of: slide) == [DrawableSize(width: 1_760, height: 120)])
  }

  /// The pre-existing bug this feature had to clear: a stack used to hand
  /// each child the child's *own* size, so inherited bounds died one level
  /// down and a nested child could never learn the container width.
  @Test("filling composes through a nested stack")
  internal func fillingComposesThroughNestedStack() {
    let slide = Slide {
      VStack {
        HStack {
          TextBox("nested").frame(maxWidth: .infinity, height: 100)
        }
        .frame(width: 900, height: 100)
      }
      .padding(80)
    }
    #expect(sizes(of: slide) == [DrawableSize(width: 900, height: 100)])
  }

  /// A filling child takes the cross axis only, so the spacer still owns
  /// the main-axis slack: 920 padded height - 200 used = 720.
  @Test("a filling child and a Spacer divide their own axes")
  internal func fillingChildCoexistsWithSpacer() {
    let slide = Slide {
      VStack {
        TextBox("top").frame(maxWidth: .infinity, height: 100)
        Spacer()
        TextBox("bottom").frame(maxWidth: .infinity, height: 100)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(80)
    }
    #expect(positions(of: slide) == [LayoutPoint(x: 80, y: 80), LayoutPoint(x: 80, y: 900)])
    #expect(
      sizes(of: slide) == [
        DrawableSize(width: 1_760, height: 100), DrawableSize(width: 1_760, height: 100),
      ])
  }

  /// Filling is opt-in: a plain `.frame(width:height:)` must keep the exact
  /// extent it authored, even inside a stack that could propose more.
  @Test("a fixed frame ignores the proposed bounds")
  internal func fixedFrameIgnoresProposal() {
    let slide = Slide {
      VStack {
        TextBox("fixed").frame(width: 400, height: 100)
      }
      .padding(80)
    }
    #expect(sizes(of: slide) == [DrawableSize(width: 400, height: 100)])
  }

  /// A drawable placed with `.position(x:y:)` outside any stack keeps both
  /// its authored position and its authored size — filling must not snap it
  /// to zero when there is no container proposing anything.
  @Test("a filling drawable outside a stack keeps its authored size")
  internal func fillingOutsideStackKeepsAuthoredSize() {
    let slide = Slide {
      TextBox("loose").position(x: 300, y: 400).frame(maxWidth: .infinity, height: 100)
    }
    #expect(positions(of: slide) == [LayoutPoint(x: 300, y: 400)])
    #expect(sizes(of: slide) == [DrawableSize(width: nil, height: 100)])
  }

  /// A ZStack has no main axis, so a filling child takes both axes.
  @Test("a filling child in a ZStack fills both axes")
  internal func fillingInDepthStack() {
    let slide = Slide {
      ZStack {
        TextBox("backdrop").frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .frame(width: 600, height: 400)
    }
    #expect(sizes(of: slide) == [DrawableSize(width: 600, height: 400)])
  }
  /// End-to-end proof that a filled frame reaches the written archive: the
  /// width is never authored anywhere, only inherited from the padded
  /// canvas (1920 - 80*2 = 1760) during the resolve pass.
  @Test("writes a filled frame's inherited width onto placeholder geometry")
  internal func writesFilledFrameSize() throws {
    let deck = Deck {
      Slide {
        VStack {
          TextBox("Fills").frame(maxWidth: .infinity, height: 120)
        }
        .padding(80)
      }
    }
    let url = FileManager.default.temporaryDirectory
      .appending(path: "flexible-\(UUID().uuidString).key")
    defer { try? FileManager.default.removeItem(at: url) }
    try deck.write(to: url)
    let bundle = try KeyBundle(contentsOfZip: Array(try Data(contentsOf: url)))
    let surgeon = try KeynoteArchiveSurgeon(bundle: bundle)
    let geometry = try firstPlaceholderGeometry(in: surgeon)
    #expect(geometry.position.x == 80)
    #expect(geometry.position.y == 80)
    #expect(geometry.size.width == 1_760)
    #expect(geometry.size.height == 120)
  }

  /// Geometry of the first drawable on the first slide.
  private func firstPlaceholderGeometry(
    in surgeon: KeynoteArchiveSurgeon
  ) throws -> TSD_GeometryArchive {
    let catalog = SlideCatalog(members: surgeon.members)
    let slides = try catalog.orderedSlides()
    let slide = try #require(slides.first)
    let archive = try KN_SlideArchive(
      serializedBytes: surgeon.members[slide.memberIndex].records[slide.recordIndex].payloads[0],
      partial: true
    )
    let identifier = try #require(archive.drawablesZOrder.first).identifier
    let location = try #require(
      try catalog.locate(recordIdentifier: identifier, named: "KN.PlaceholderArchive")
    )
    let placeholder = try KN_PlaceholderArchive(
      serializedBytes: surgeon.members[location.memberIndex]
        .records[location.recordIndex]
        .payloads[location.payloadIndex],
      partial: true
    )
    return placeholder.super.super.super.geometry
  }

  /// The resolved positions of a slide's drawables, in declaration order.
  private func positions(of slide: Slide) -> [LayoutPoint] {
    slide.resolvedPositions
  }

  /// The resolved sizes of a slide's drawables, in declaration order.
  ///
  /// Sizing is what flexible frames change, and it is invisible to
  /// ``positions(of:)`` — a filling box and a zero-width one can share an
  /// origin while differing entirely in extent.
  private func sizes(of slide: Slide) -> [DrawableSize] {
    slide.resolvedSizes
  }
}
