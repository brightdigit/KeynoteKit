import Testing

@testable import KeynoteKit

/// Layout primitives (#65): stacks resolve to the absolute positions the
/// surgeon already writes, entirely at build time.
@Suite("Layout primitives")
internal struct LayoutPrimitivesTests {
  @Test("a VStack advances children down by their heights plus spacing")
  internal func verticalStackAdvances() {
    let slide = Slide {
      VStack(spacing: 20) {
        TextBox("a").frame(width: 400, height: 100)
        TextBox("b").frame(width: 400, height: 60)
        TextBox("c").frame(width: 400, height: 80)
      }
    }
    #expect(
      positions(of: slide) == [
        LayoutPoint(x: 0, y: 0), LayoutPoint(x: 0, y: 120), LayoutPoint(x: 0, y: 200),
      ])
  }

  @Test("an HStack advances children right by their widths plus spacing")
  internal func horizontalStackAdvances() {
    let slide = Slide {
      HStack(spacing: 10) {
        TextBox("a").frame(width: 100, height: 50)
        TextBox("b").frame(width: 200, height: 50)
      }
    }
    #expect(positions(of: slide) == [LayoutPoint(x: 0, y: 0), LayoutPoint(x: 110, y: 0)])
  }

  @Test("a ZStack overlays its children on one origin")
  internal func depthStackOverlays() {
    let slide = Slide {
      ZStack {
        TextBox("under").frame(width: 300, height: 200)
        TextBox("over").frame(width: 300, height: 200)
      }
    }
    #expect(positions(of: slide) == [LayoutPoint(x: 0, y: 0), LayoutPoint(x: 0, y: 0)])
  }

  @Test("center alignment offsets children by half the cross-axis slack")
  internal func centerAlignment() {
    let slide = Slide {
      VStack(alignment: .center) {
        TextBox("wide").frame(width: 400, height: 50)
        TextBox("narrow").frame(width: 100, height: 50)
      }
      .frame(width: 400, height: 100)
    }
    // The narrow child centres in the 400pt frame: (400 - 100) / 2.
    #expect(positions(of: slide) == [LayoutPoint(x: 0, y: 0), LayoutPoint(x: 150, y: 50)])
  }

  @Test("trailing alignment pushes children to the far edge")
  internal func trailingAlignment() {
    let slide = Slide {
      VStack(alignment: .trailing) {
        TextBox("wide").frame(width: 400, height: 50)
        TextBox("narrow").frame(width: 100, height: 50)
      }
      .frame(width: 400, height: 100)
    }
    #expect(positions(of: slide) == [LayoutPoint(x: 0, y: 0), LayoutPoint(x: 300, y: 50)])
  }

  @Test("vertical center alignment centers content vertically inside the frame")
  internal func verticalCenterAlignment() {
    let slide = Slide {
      VStack(verticalAlignment: .center) {
        TextBox("a").frame(width: 200, height: 50)
        TextBox("b").frame(width: 200, height: 50)
      }
      .frame(width: 400, height: 200)
    }
    // 200 frame - 100 content = 100 slack -> initial y offset 50.
    #expect(positions(of: slide) == [LayoutPoint(x: 0, y: 50), LayoutPoint(x: 0, y: 100)])
  }

  @Test("vertical bottom alignment aligns content to the bottom of the frame")
  internal func verticalBottomAlignment() {
    let slide = Slide {
      VStack(verticalAlignment: .bottom) {
        TextBox("a").frame(width: 200, height: 50)
        TextBox("b").frame(width: 200, height: 50)
      }
      .frame(width: 400, height: 200)
    }
    // 200 frame - 100 content = 100 slack -> initial y offset 100.
    #expect(positions(of: slide) == [LayoutPoint(x: 0, y: 100), LayoutPoint(x: 0, y: 150)])
  }

  @Test("vertical center alignment overflows symmetrically up and down when overflowing")
  internal func verticalCenterOverflow() {
    let slide = Slide {
      VStack(verticalAlignment: .center) {
        TextBox("a").frame(width: 200, height: 200)
        TextBox("b").frame(width: 200, height: 200)
      }
      .frame(width: 400, height: 200)
    }
    // 200 frame - 400 content = -200 -> initial y offset -100.
    #expect(positions(of: slide) == [LayoutPoint(x: 0, y: -100), LayoutPoint(x: 0, y: 100)])
  }

  @Test("nested stacks compose their offsets")
  internal func nestedStacks() {
    let slide = Slide {
      VStack(spacing: 50) {
        TextBox("header").frame(width: 600, height: 100)
        HStack(spacing: 20) {
          TextBox("left").frame(width: 200, height: 200)
          TextBox("right").frame(width: 200, height: 200)
        }
      }
    }
    // Header at 0; the row starts at 100 + 50 spacing = 150.
    #expect(
      positions(of: slide) == [
        LayoutPoint(x: 0, y: 0), LayoutPoint(x: 0, y: 150), LayoutPoint(x: 220, y: 150),
      ])
  }

  @Test("padding insets a child on every edge it names")
  internal func paddingInsets() {
    let slide = Slide {
      VStack {
        TextBox("padded")
          .frame(width: 100, height: 100)
          .padding(EdgeInsets(top: 30, leading: 40))
        TextBox("after").frame(width: 100, height: 100)
      }
    }
    // First child offsets by its own insets; the second clears the padded
    // child's full height (100 + 30 top inset).
    #expect(positions(of: slide) == [LayoutPoint(x: 40, y: 30), LayoutPoint(x: 0, y: 130)])
  }

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
  ///
  /// A stack only lacks bounds when nested inside an unframed parent, and
  /// there a spacer collapses to zero rather than erroring.
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

  @Test("a Spacer nested in an unframed stack collapses to zero")
  internal func spacerWithoutBoundsCollapses() {
    let slide = Slide {
      HStack {
        VStack {
          TextBox("top").frame(width: 100, height: 100)
          Spacer()
          TextBox("bottom").frame(width: 100, height: 100)
        }
      }
    }
    #expect(positions(of: slide) == [LayoutPoint(x: 0, y: 0), LayoutPoint(x: 0, y: 100)])
  }

  /// The regression that matters most: every existing deck positions its
  /// drawables with `.position(x:y:)` and no stack. Those must be untouched.
  @Test("drawables outside a stack keep their authored positions")
  internal func unstackedDrawablesKeepPositions() {
    let slide = Slide {
      TextBox("a").position(x: 160, y: 220)
      TextBox("b").position(x: 700, y: 480)
    }
    #expect(positions(of: slide) == [LayoutPoint(x: 160, y: 220), LayoutPoint(x: 700, y: 480)])
  }

  /// An unsized child contributes zero extent, so siblings pile up at the
  /// same offset. Intrinsic measurement is #67; until then a stack's
  /// children need explicit frames.
  @Test("an unsized child advances the stack by nothing")
  internal func unsizedChildAdvancesNothing() {
    let slide = Slide {
      VStack {
        TextBox("no frame")
        TextBox("after").frame(width: 100, height: 100)
      }
    }
    #expect(positions(of: slide) == [LayoutPoint(x: 0, y: 0), LayoutPoint(x: 0, y: 0)])
  }

  @Test("top-level padding insets a top-level stack or element from top-left")
  internal func topLevelPaddingInsets() {
    let slide = Slide {
      VStack {
        TextBox("padded").frame(width: 100, height: 100)
      }.padding(EdgeInsets(top: 80, leading: 80))
    }
    #expect(positions(of: slide) == [LayoutPoint(x: 80, y: 80)])
  }

  /// The resolved positions of a slide's drawables, in declaration order.
  ///
  /// `LayoutPoint` is `Equatable`, so these assertions compare directly —
  /// the hand-rolled `==` on `[(Double, Double)]` this file used to carry
  /// existed only because tuples are not.
  private func positions(of slide: Slide) -> [LayoutPoint] {
    slide.resolvedPositions
  }
}
