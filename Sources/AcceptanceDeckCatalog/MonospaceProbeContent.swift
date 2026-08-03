//
//  MonospaceProbeContent.swift
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

/// The #64 monospace probe — **round two**.
///
/// Round one failed, but not the way it looked. All four families rendered
/// at the template's default size *and* default proportional face, including
/// `Courier New`, which unquestionably exists and is unquestionably
/// monospaced. A font-availability problem cannot explain that.
///
/// An archive probe confirmed KeynoteKit writes the authored values
/// correctly: `fontName=Menlo fontSize=96.0` lands in a
/// `TSWP.ParagraphStyleArchive` variation, identically for single-line and
/// multi-line boxes. So the bytes are right and Keynote ignored them.
///
/// The one structural difference from `TextFormattingContent` — the deck
/// that *does* render its authored font — is paragraph count. That deck is
/// a **single** paragraph; every round-one probe box was
/// **multi**-paragraph (`"iiii\nMMMM\n1111"`).
///
/// This round isolates that variable. Slides 1–3 hold paragraph count fixed
/// at one and vary only the family; slides 4–5 hold the family fixed and
/// vary paragraph count and styling route. Read them together:
///
/// - **Slides 1–3 render monospaced, slide 4 does not** → the whole-item
///   paragraph-style variation is only honored for single-paragraph items.
///   That is a KeynoteKit bug, not a font problem, and it needs its own
///   issue before #66 can rely on `.font()`.
/// - **Slide 4 fails but slide 5 renders** → the per-paragraph route is the
///   workaround, and #66 should emit spans rather than item-level styling.
/// - **Nothing renders monospaced, including slide 1** → the earlier
///   `TextFormattingContent` render evidence is stale and whole-item font
///   selection regressed generally.
/// - **Everything renders monospaced** → round one's failure was an export
///   artifact; re-run round one before trusting it.
package struct MonospaceProbeContent: SlideContent {
  /// The equal-width ruler as a single paragraph: identical widths mean a
  /// real monospaced face, ragged ones mean a proportional substitute.
  ///
  /// Round one stacked these three groups on separate lines, which is
  /// exactly the multi-paragraph shape now under suspicion — so round one
  /// could not distinguish "font ignored" from "font substituted".
  private static let ruler = "iiii MMMM 1111"

  package var body: some SlideContent {
    singleParagraphSlide("Menlo", index: 1)
    singleParagraphSlide("Courier New", index: 2)
    singleParagraphSlide("Monaco", index: 3)
    multiParagraphSlide
    perParagraphSlide
  }

  /// Slide 4: three lines in one box, styled at the item level — the shape
  /// that failed in round one.
  private var multiParagraphSlide: Slide {
    Slide {
      TextBox("4 - multi-paragraph, item-level font")
        .position(x: 120, y: 100)
        .frame(width: 1_600, height: 80)
        .fontSize(40)
      TextBox("iiii\nMMMM\n1111")
        .font("Menlo", size: 96)
        .position(x: 120, y: 280)
        .frame(width: 1_400, height: 600)
    }
  }

  /// Slide 5: the same three lines as explicit ``Paragraph`` values, each
  /// carrying its own styled ``Text`` span.
  private var perParagraphSlide: Slide {
    Slide {
      TextBox("5 - per-paragraph Text spans")
        .position(x: 120, y: 100)
        .frame(width: 1_600, height: 80)
        .fontSize(40)
      TextBox {
        Paragraph { Text("iiii").font("Menlo", size: 96) }
        Paragraph { Text("MMMM").font("Menlo", size: 96) }
        Paragraph { Text("1111").font("Menlo", size: 96) }
      }
      .position(x: 120, y: 280)
      .frame(width: 1_400, height: 600)
    }
  }

  /// Creates the content.
  package init() {}

  /// One family on a **single** paragraph — the shape known to render.
  private func singleParagraphSlide(_ family: String, index: Int) -> Slide {
    Slide {
      TextBox("\(index) - \(family), single paragraph")
        .position(x: 120, y: 100)
        .frame(width: 1_400, height: 90)
        .fontSize(40)
      TextBox(Self.ruler)
        .font(family, size: 96)
        .position(x: 120, y: 300)
        .frame(width: 1_600, height: 200)
    }
  }
}
