//
//  BackgroundFillContent.swift
//  KeynoteKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import KeynoteKit

/// Background fill (#78) for the human render pass. The structural tests
/// prove the fill lands in the archive; only a human can confirm Keynote
/// *draws* it, behind the text rather than over it.
///
/// **One box per slide wherever a fill is under test.** Keynote lays a
/// placeholder out at the layout master's width, ignoring the authored
/// frame (#52), so side-by-side boxes overlap and one fill bleeds under its
/// neighbour — which would make these slides show the opposite of what they
/// claim.
///
/// Green means:
/// - slide 1: a dark panel behind light text — the code-panel treatment the
///   demo deck (#56) needs; the text is legible, so the fill is painted
///   underneath, not on top
/// - slide 2: a filled box above an unfilled one; the unfilled box shows the
///   slide background, proving the fill is opt-in
/// - slide 3: fill plus bottom alignment on one fork
/// - slide 4: fill plus two columns; the fill covers the whole box including
///   the gutter, not just the text runs
/// - slide 5: a semi-transparent fill over a filled neighbour, showing alpha
///   survives the round trip
package struct BackgroundFillContent: SlideContent {
  /// The panel color: near-black with a blue cast, a typical code theme.
  private static let panel = Color(red: 0.11, green: 0.13, blue: 0.17)

  /// Light text for use on ``panel``.
  private static let onPanel = Color(red: 0.92, green: 0.94, blue: 0.96)

  /// Filler long enough to flow across columns.
  private static let filler = Array(
    repeating: "lorem ipsum dolor sit amet consectetur adipiscing elit",
    count: 12
  )
  .joined(separator: " ")

  package var body: some SlideContent {
    codePanelSlide
    optInSlide
    alignmentSlide
    columnsSlide
    alphaSlide
  }

  /// A dark panel with light text — the #56 code-panel treatment.
  ///
  /// Deliberately a **single** paragraph. Multi-paragraph boxes silently
  /// drop item-level formatting (#81), so a multi-line code sample here
  /// would render dark-on-dark and this slide would fail for a reason that
  /// has nothing to do with the fill. Restore the multi-line sample once
  /// #81 is fixed — that is the shape the demo deck actually needs.
  private var codePanelSlide: Slide {
    Slide {
      TextBox("dark panel, light text")
        .position(x: 120, y: 80)
        .frame(width: 1_600, height: 70)
        .fontSize(40)
      TextBox("try deck.write(to: url)")
        .background(Self.panel)
        .foregroundColor(Self.onPanel)
        .font("Menlo", size: 44)
        .position(x: 120, y: 300)
        .frame(width: 1_600, height: 300)
    }
  }

  /// A filled box above an unfilled one: the fill must be opt-in.
  ///
  /// Stacked vertically with a wide gap rather than placed side by side.
  /// Keynote lays a placeholder out at the layout master's width, ignoring
  /// the authored frame (#52), so horizontally adjacent boxes overlap and a
  /// neighbour's fill bleeds under the box that is meant to prove *absence*
  /// of fill — the slide would then show the opposite of its point.
  private var optInSlide: Slide {
    Slide {
      TextBox("filled")
        .background(Color(red: 0.85, green: 0.25, blue: 0.2))
        .foregroundColor(Self.onPanel)
        .position(x: 100, y: 120)
        .frame(width: 1_600, height: 300)
        .fontSize(40)
      TextBox("NOT filled - slide background shows through")
        .position(x: 100, y: 700)
        .frame(width: 1_600, height: 300)
        .fontSize(40)
    }
  }

  /// Fill composed with vertical alignment — both shape-style properties
  /// on one fork. One box per slide, per the #52 overlap caveat above.
  private var alignmentSlide: Slide {
    Slide {
      TextBox("fill + bottom alignment")
        .background(Self.panel)
        .foregroundColor(Self.onPanel)
        .verticalAlignment(.bottom)
        .position(x: 100, y: 100)
        .frame(width: 1_600, height: 800)
        .fontSize(36)
    }
  }

  /// Fill composed with columns: the fill must cover the whole box, gutter
  /// included, rather than only the text runs.
  private var columnsSlide: Slide {
    Slide {
      TextBox("FILL + COLUMNS " + Self.filler)
        .background(Color(red: 0.18, green: 0.3, blue: 0.22))
        .foregroundColor(Self.onPanel)
        .columns(2, gap: 41.25)
        .position(x: 100, y: 100)
        .frame(width: 1_600, height: 800)
        .fontSize(20)
    }
  }

  /// A translucent fill over an opaque one: alpha must survive.
  private var alphaSlide: Slide {
    Slide {
      TextBox("opaque")
        .background(Color(red: 0.85, green: 0.7, blue: 0.1))
        .position(x: 200, y: 250)
        .frame(width: 900, height: 400)
        .fontSize(40)
      TextBox("40% alpha overlapping")
        .background(Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.4))
        .foregroundColor(Self.onPanel)
        .zIndex(1)
        .position(x: 600, y: 400)
        .frame(width: 900, height: 400)
        .fontSize(40)
    }
  }

  /// Creates the content.
  package init() {}
}
