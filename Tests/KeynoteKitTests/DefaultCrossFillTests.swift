import Foundation
import Testing

@testable import KeynoteKit

/// Default cross-axis fill: a stack child takes the container's cross extent
/// unless it authored one, so `.frame(maxWidth: .infinity)` is only needed to
/// fill a stack's *main* axis.
@Suite("Default cross-axis fill")
internal struct DefaultCrossFillTests {
  /// An image with a known pixel size, declared rather than decoded.
  ///
  /// The natural extent is what these tests assert on, so it is supplied
  /// directly — a hand-rolled JPEG header would test `JPEGSize`, not layout.
  private var sampleImage: Image {
    Image(data: Data([0xFF, 0xD8, 0xFF, 0xD9]), naturalWidth: 320, naturalHeight: 240)
  }

  /// The headline: no `maxWidth:` is written anywhere, yet the box spans the
  /// padded canvas (1920 - 80*2 = 1760).
  @Test("an unauthored child fills the cross axis by default")
  internal func unauthoredChildFillsCrossAxisByDefault() {
    let slide = Slide {
      VStack {
        TextBox("fills").frame(height: 100)
      }
      .padding(80)
    }
    #expect(positions(of: slide) == [LayoutPoint(x: 80, y: 80)])
    #expect(sizes(of: slide) == [DrawableSize(width: 1_760, height: 100)])
  }

  /// Filling is a fallback, not an override — an authored extent still wins,
  /// which is what keeps cross-axis alignment meaningful.
  @Test("an authored cross extent beats the default fill")
  internal func authoredCrossExtentBeatsDefaultFill() {
    let slide = Slide {
      VStack(alignment: .center) {
        TextBox("wide").frame(height: 50)
        TextBox("narrow").frame(width: 400, height: 50)
      }
      .padding(80)
    }
    #expect(
      sizes(of: slide) == [
        DrawableSize(width: 1_760, height: 50), DrawableSize(width: 400, height: 50),
      ])
    // The authored child still centres in the 1760 container: (1760-400)/2.
    #expect(positions(of: slide) == [LayoutPoint(x: 80, y: 80), LayoutPoint(x: 760, y: 130)])
  }

  /// The dangerous edge. Without bounds, `crossExtent` falls back to the
  /// widest sibling — which is zero when every sibling is unauthored too.
  /// Filling from that value would silently resize drawables to nothing, so
  /// an unbounded stack must leave the axis unauthored instead.
  @Test("default fill leaves the axis alone when the stack has no bounds")
  internal func defaultFillCollapsesToNothingWithoutBounds() {
    let slide = Slide {
      HStack {
        VStack {
          TextBox("inner").frame(height: 100)
        }
      }
    }
    #expect(sizes(of: slide) == [DrawableSize(width: nil, height: 100)])
  }

  /// An image is whatever size its source is: natural pixel extent on both
  /// axes, so the stack has nothing to fill.
  @Test("an image keeps its source size inside a stack")
  internal func imageKeepsSourceSizeInStack() {
    let slide = Slide {
      VStack {
        sampleImage
      }
      .padding(80)
    }
    #expect(sizes(of: slide) == [DrawableSize(width: 320, height: 240)])
  }

  /// The pre-existing bug the source-size rule fixes: an unframed image used
  /// to report zero extent, so the next child drew on top of it.
  @Test("an unframed image advances the stack by its natural height")
  internal func unframedImageAdvancesStackByNaturalHeight() {
    let slide = Slide {
      VStack {
        sampleImage
        TextBox("after").frame(width: 100, height: 50)
      }
    }
    #expect(positions(of: slide) == [LayoutPoint(x: 0, y: 0), LayoutPoint(x: 0, y: 240)])
  }

  /// A depth stack has no cross axis to speak of, and SwiftUI's `ZStack`
  /// does not stretch its children either.
  @Test("default fill does not apply in a depth stack")
  internal func defaultFillDoesNotApplyInDepthStack() {
    let slide = Slide {
      ZStack {
        TextBox("overlay").frame(height: 100)
      }
      .frame(width: 600, height: 400)
    }
    #expect(sizes(of: slide) == [DrawableSize(width: nil, height: 100)])
  }

  /// The mirror image: an `HStack`'s cross axis is height, so an unauthored
  /// height fills instead of an unauthored width.
  @Test("an HStack fills a child's height by default")
  internal func horizontalStackFillsChildHeightByDefault() {
    let slide = Slide {
      HStack {
        TextBox("fills").frame(width: 200)
      }
      .padding(80)
    }
    // 1080 canvas - 80*2 = 920 of padded height.
    #expect(sizes(of: slide) == [DrawableSize(width: 200, height: 920)])
  }

  /// Padding must stay transparent to the fill decision, or wrapping a child
  /// in `.padding()` would silently pin it to its intrinsic extent.
  @Test("padding is transparent to the default fill")
  internal func paddingIsTransparentToDefaultFill() {
    let slide = Slide {
      VStack {
        TextBox("padded").frame(height: 100).padding(20)
      }
      .padding(80)
    }
    // 1760 padded canvas, less the child's own 20pt insets on each side.
    #expect(positions(of: slide) == [LayoutPoint(x: 100, y: 100)])
    #expect(sizes(of: slide) == [DrawableSize(width: 1_720, height: 100)])
  }

  /// The single-axis overload exists so a height can be named without
  /// restating a width — the whole point of the default.
  @Test("frame(height:) leaves the width unauthored")
  internal func frameHeightOnlyLeavesWidthUnauthored() {
    let box = TextBox("x").frame(height: 120)
    #expect(box.authoredSize == DrawableSize(width: nil, height: 120))
    let sized = TextBox("y").frame(width: 300)
    #expect(sized.authoredSize == DrawableSize(width: 300, height: nil))
  }

  /// The demo's title-slide shape, reproduced here because the test target
  /// does not depend on `KeynoteKitDemo`. No width is authored anywhere: the
  /// 1760 comes entirely from the padded canvas via the default fill, and
  /// the spacers centre the pair without naming a y offset.
  @Test("the demo's title-slide shape needs no authored width")
  internal func demoTitleSlideShapeNeedsNoAuthoredWidth() {
    let margin = 80.0
    let slide = Slide {
      VStack(spacing: 40) {
        Spacer()
        TextBox("KeynoteKit").frame(height: 120).fontSize(72).bold()
        TextBox("Authored from Swift").frame(height: 80).fontSize(36)
        Spacer()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(margin)
    }
    #expect(
      sizes(of: slide) == [
        DrawableSize(width: 1_760, height: 120), DrawableSize(width: 1_760, height: 80),
      ])
    // 920 padded height - 200 content - 3 gaps of 40 = 600, so 300 a spacer:
    // the first box lands at 80 margin + 300 spacer + 40 spacing.
    #expect(positions(of: slide) == [LayoutPoint(x: 80, y: 420), LayoutPoint(x: 80, y: 580)])
  }

  /// The resolved positions of a slide's drawables, in declaration order.
  private func positions(of slide: Slide) -> [LayoutPoint] {
    slide.resolvedPositions
  }

  /// The resolved sizes of a slide's drawables, in declaration order.
  private func sizes(of slide: Slide) -> [DrawableSize] {
    slide.resolvedSizes
  }
}
