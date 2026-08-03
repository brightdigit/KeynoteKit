//
//  MultiParagraphFormattingContent.swift
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

/// Multi-paragraph item formatting (#81) for the human render pass.
///
/// Before the fix, item-level `.font`/`.fontSize`/`.foregroundColor` reached
/// only the **first** paragraph: the surgeon collapsed runs of identical
/// paragraph formats into one `tableParaStyle` entry at offset 0, and
/// Keynote styled just that paragraph. The archive stayed valid, so nothing
/// failed until someone looked at a slide.
///
/// Every box here is **three or more** paragraphs on purpose. A
/// two-paragraph case exercises only the first and last and would pass while
/// interior paragraphs stayed broken — which is how the per-span variant of
/// this bug hid during the #64 probe.
///
/// Green means:
/// - slide 1: all three lines Menlo, equal width, large — not just `iiii`
/// - slide 2: all five lines large, bold, and red
/// - slide 3: the middle paragraph is styled like its neighbours (this is
///   the case per-span styling used to miss)
/// - slide 4: per-paragraph alignment still works — left, centre, right,
///   then two more left lines
package struct MultiParagraphFormattingContent: SlideContent {
  /// Light text for the dark panels.
  private static let ink = TextColor(red: 0.85, green: 0.12, blue: 0.1)

  package var body: some SlideContent {
    monospaceSlide
    weightAndColorSlide
    interiorSlide
    alignmentSlide
  }

  /// Item-level font across three paragraphs.
  private var monospaceSlide: Slide {
    Slide {
      TextBox("1 - all three lines should be Menlo")
        .position(x: 100, y: 60)
        .frame(width: 1_700, height: 70)
        .fontSize(36)
      TextBox("iiii\nMMMM\n1111")
        .font("Menlo", size: 90)
        .position(x: 100, y: 220)
        .frame(width: 1_700, height: 700)
    }
  }

  /// Item-level weight and color across five paragraphs.
  private var weightAndColorSlide: Slide {
    Slide {
      TextBox("2 - all five lines should be bold red")
        .position(x: 100, y: 60)
        .frame(width: 1_700, height: 70)
        .fontSize(36)
      TextBox("one\ntwo\nthree\nfour\nfive")
        .bold()
        .foregroundColor(Self.ink)
        .fontSize(56)
        .position(x: 100, y: 220)
        .frame(width: 1_700, height: 700)
    }
  }

  /// The interior paragraph specifically — per-span styling used to skip it.
  private var interiorSlide: Slide {
    Slide {
      TextBox("3 - the MIDDLE line must match its neighbours")
        .position(x: 100, y: 60)
        .frame(width: 1_700, height: 70)
        .fontSize(36)
      TextBox {
        Paragraph { Text("first").font("Menlo", size: 72) }
        Paragraph { Text("middle").font("Menlo", size: 72) }
        Paragraph { Text("last").font("Menlo", size: 72) }
      }
      .position(x: 100, y: 220)
      .frame(width: 1_700, height: 700)
    }
  }

  /// Per-paragraph alignment must survive the per-paragraph entries.
  private var alignmentSlide: Slide {
    Slide {
      TextBox("4 - left, centre, right, then two more left")
        .position(x: 100, y: 60)
        .frame(width: 1_700, height: 70)
        .fontSize(36)
      TextBox {
        Paragraph("left")
        Paragraph("centre").alignment(.center)
        Paragraph("right").alignment(.right)
        Paragraph("left again")
        Paragraph("still left")
      }
      .fontSize(48)
      .position(x: 100, y: 220)
      .frame(width: 1_700, height: 700)
    }
  }

  /// Creates the content.
  package init() {}
}
