import Testing

@testable import KeynoteKit

/// `Spacer` distribution (#65): a spacer divides whatever slack its stack
/// has. Since an unframed stack fills its parent's cross axis, that slack is
/// usually inherited all the way from the slide canvas.
@Suite("Spacer distribution")
internal struct SpacerDistributionTests {
  @Test("a Spacer divides a bounded stack's slack")
  internal func spacerDividesSlack() {
    let slide = Slide {
      VStack {
        TextBox("top").frame(width: 100, height: 100)
        Spacer()
        TextBox("bottom").frame(width: 100, height: 100)
      }
      .frame(width: 100, height: 500)
    }
    // 500 - 200 used = 300 of slack to the single spacer.
    #expect(positions(of: slide) == [LayoutPoint(x: 0, y: 0), LayoutPoint(x: 0, y: 400)])
  }

  @Test("two Spacers split the slack equally")
  internal func twoSpacersSplitEqually() {
    let slide = Slide {
      VStack {
        Spacer()
        TextBox("middle").frame(width: 100, height: 100)
        Spacer()
      }
      .frame(width: 100, height: 500)
    }
    // 400 of slack halves to 200, centring the child.
    #expect(positions(of: slide) == [LayoutPoint(x: 0, y: 200)])
  }

  /// A top-level stack inherits the slide canvas as its bounds, so a
  /// `Spacer` works without an explicit `.frame()` — the common case of
  /// pinning content to the top and bottom of a slide.
  @Test("a top-level Spacer divides the slide canvas")
  internal func spacerUsesSlideCanvas() {
    let slide = Slide {
      VStack {
        TextBox("top").frame(width: 100, height: 100)
        Spacer()
        TextBox("bottom").frame(width: 100, height: 100)
      }
    }
    // 1080 canvas - 200 used = 880 of slack to the single spacer.
    #expect(positions(of: slide) == [LayoutPoint(x: 0, y: 0), LayoutPoint(x: 0, y: 980)])
  }

  /// An unframed stack authors no extent, so it fills its parent's cross
  /// axis and inherits real bounds — which its own children then have slack
  /// to divide. A nested `Spacer` therefore works like a top-level one.
  ///
  /// This supersedes the older rule that a nested spacer collapsed to zero.
  /// That collapse was a consequence of bounds dying at the outer stack, not
  /// a behavior worth keeping: the outer `HStack` here is unauthored on both
  /// axes, so it takes the 1920x1080 canvas and passes the height down.
  @Test("a Spacer nested in an unframed stack divides the inherited bounds")
  internal func spacerNestedInUnframedStackDividesBounds() {
    let slide = Slide {
      HStack {
        VStack {
          TextBox("top").frame(width: 100, height: 100)
          Spacer()
          TextBox("bottom").frame(width: 100, height: 100)
        }
      }
    }
    // 1080 inherited canvas height - 200 used = 880 of slack to the spacer.
    #expect(positions(of: slide) == [LayoutPoint(x: 0, y: 0), LayoutPoint(x: 0, y: 980)])
  }
  /// The resolved positions of a slide's drawables, in declaration order.
  private func positions(of slide: Slide) -> [LayoutPoint] {
    slide.resolvedPositions
  }
}
