//
//  TextLayoutContent.swift
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

/// Text layout (#51) for the human render pass. Green means: slide 1 shows
/// plain / "•" / "→" / numbered lists; slide 2 shows the five paragraph
/// treatments; slide 3 shows top / middle / bottom text; slides 4–5 show
/// 2- and 3-column flows with a visible gutter; slide 6 shows the three
/// rotated boxes.
package struct TextLayoutContent: SlideContent {
  /// Filler long enough to flow into every column.
  private static let filler = Array(
    repeating: "lorem ipsum dolor sit amet consectetur adipiscing elit sed do",
    count: 18
  )
  .joined(separator: " ")

  package var body: some SlideContent {
    listStyleSlide
    paragraphSlide
    verticalAlignmentSlide
    twoColumnSlide
    threeColumnSlide
    rotationSlide
  }

  /// Plain by default, theme bullet, custom bullet, numbered.
  private var listStyleSlide: Slide {
    Slide {
      TextBox("plain by default\nno bullets here")
        .position(x: 100, y: 60)
        .fontSize(28)
      TextBox("theme bullet one\ntheme bullet two")
        .listStyle(.bullet)
        .position(x: 100, y: 300)
        .fontSize(28)
      TextBox("arrow one\narrow two")
        .listStyle(.bullet("→"))
        .position(x: 100, y: 540)
        .fontSize(28)
      TextBox("first numbered\nsecond numbered\nthird numbered")
        .listStyle(.numbered())
        .position(x: 100, y: 780)
        .fontSize(28)
    }
  }

  /// Item-wide alignment plus per-paragraph overrides and indents.
  private var paragraphSlide: Slide {
    Slide {
      TextBox {
        Paragraph("item-wide left alignment")
        Paragraph("centered paragraph").alignment(.center)
        Paragraph("right-aligned paragraph").alignment(.right)
        Paragraph("left indent 120pt").indent(120)
        Paragraph("first-line indent 120pt over two lines so the hanging shape shows")
          .indent(0, firstLine: 120)
      }
      .position(x: 100, y: 200)
      .fontSize(36)
    }
  }

  /// Top, middle, and bottom vertical alignment in tall boxes.
  private var verticalAlignmentSlide: Slide {
    Slide {
      TextBox("TOP")
        .verticalAlignment(.top)
        .position(x: 100, y: 100)
        .frame(width: 500, height: 880)
        .fontSize(48)
      TextBox("MIDDLE")
        .verticalAlignment(.middle)
        .position(x: 700, y: 100)
        .frame(width: 500, height: 880)
        .fontSize(48)
      TextBox("BOTTOM")
        .verticalAlignment(.bottom)
        .position(x: 1_300, y: 100)
        .frame(width: 500, height: 880)
        .fontSize(48)
    }
  }

  /// A two-column flow with a 41.25pt gutter (the fixture's 5%). One
  /// column box per slide: the flow fills the layout height before the
  /// second column starts, so stacked column boxes would overlap.
  private var twoColumnSlide: Slide {
    Slide {
      TextBox("TWO COLUMNS " + Self.filler + " " + Self.filler)
        .columns(2, gap: 41.25)
        .position(x: 100, y: 60)
        .frame(width: 900, height: 900)
        .fontSize(20)
    }
  }

  /// A three-column flow with the same gutter.
  private var threeColumnSlide: Slide {
    Slide {
      TextBox("THREE COLUMNS " + Self.filler)
        .columns(3, gap: 41.25)
        .position(x: 100, y: 60)
        .frame(width: 900, height: 900)
        .fontSize(20)
    }
  }

  /// Clockwise 45°, counterclockwise 45°, and a quarter turn.
  private var rotationSlide: Slide {
    Slide {
      TextBox("clockwise 45")
        .rotationEffect(.degrees(45))
        .position(x: 150, y: 400)
        .frame(width: 400, height: 80)
        .fontSize(36)
      TextBox("counterclockwise 45")
        .rotationEffect(.degrees(-45))
        .position(x: 700, y: 400)
        .frame(width: 500, height: 80)
        .fontSize(36)
      TextBox("quarter turn")
        .rotationEffect(.radians(.pi / 2))
        .position(x: 1_400, y: 400)
        .frame(width: 400, height: 80)
        .fontSize(36)
    }
  }

  /// Creates the content.
  package init() {}
}
