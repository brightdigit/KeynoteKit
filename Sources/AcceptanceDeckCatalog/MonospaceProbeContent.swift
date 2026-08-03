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

/// The #64 monospace probe: does a monospaced family actually resolve in
/// Keynote 15.3, or does Keynote silently substitute a proportional face?
///
/// Font *family* selection is already proven — `TextBox.font(_:size:)` ships
/// render-verified as `.font("HelveticaNeue", size: 48)` in
/// ``TextFormattingContent``. What is unproven is monospace specifically,
/// which gates the code-on-slide demo design (#66, #56).
///
/// **How to read each family slide.** The three ruler lines `iiii` / `MMMM` /
/// `1111` are the signal. In a genuinely monospaced face all three are the
/// **same width**, so their right edges line up in a column. Under a
/// proportional substitute `MMMM` is dramatically wider than `iiii` and the
/// edges are ragged. This is legible at a glance — no measuring required.
///
/// The final slide checks that leading-space indentation holds its columns,
/// which is what #66 actually depends on: syntax-highlighted code is worthless
/// if the indentation drifts.
package struct MonospaceProbeContent: SlideContent {
  /// The candidate families, in preference order for the demo deck.
  ///
  /// `Menlo` and `Monaco` ship with macOS. `SF Mono` is present but was
  /// historically not exposed to the font picker in some releases, so it is
  /// the one most likely to substitute. `Courier New` is the conservative
  /// fallback that should always resolve.
  private static let families = ["Menlo", "SF Mono", "Courier New", "Monaco"]

  /// The equal-width ruler: identical widths mean a real monospaced face.
  private static let ruler = "iiii\nMMMM\n1111"

  /// Nested leading-space lines whose left edges must form clean columns.
  private static let indented = """
    func render() {
      for slide in deck {
        slide.draw()
      }
    }
    """

  package var body: some SlideContent {
    for family in Self.families {
      familySlide(family)
    }
    indentationSlide
  }

  /// Leading-space indentation in the first candidate family.
  ///
  /// Uses `Menlo` specifically — if the ruler slides show `Menlo`
  /// substituting, this slide's result is meaningless and should be re-run
  /// against whichever family did survive.
  private var indentationSlide: Slide {
    Slide {
      TextBox("indentation — Menlo")
        .position(x: 120, y: 100)
        .frame(width: 1_200, height: 80)
        .fontSize(44)
      TextBox(Self.indented)
        .font("Menlo", size: 40)
        .position(x: 120, y: 260)
        .frame(width: 1_400, height: 600)
    }
  }

  /// Creates the content.
  package init() {}

  /// One family under test: its name, then the equal-width ruler.
  private func familySlide(_ family: String) -> Slide {
    Slide {
      TextBox(family)
        .position(x: 120, y: 100)
        .frame(width: 1_200, height: 90)
        .fontSize(56)
      TextBox(Self.ruler)
        .font(family, size: 96)
        .position(x: 120, y: 280)
        .frame(width: 1_200, height: 600)
    }
  }
}
