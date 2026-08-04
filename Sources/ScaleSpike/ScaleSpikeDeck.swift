//
//  ScaleSpikeDeck.swift
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

/// Builds the #63 timing deck: a demo-shaped deck of `n` slides.
///
/// Shaped like the real demo (#56) rather than minimally — a title, a code
/// block, and a caption per slide, with a transition and a build — because
/// the cost being measured scales with *records per member*, not just slide
/// count. A deck of bare one-drawable slides would understate it.
internal enum ScaleSpikeDeck {
  /// Drawables authored on every slide.
  internal static let drawablesPerSlide = 4

  /// Code-shaped filler; the demo's slides are code-heavy.
  private static let code = """
    func write(deck: Deck) throws {
      let url = URL(filePath: "out.key")
      try deck.write(to: url)
    }
    """

  /// A deck of `slides` demo-shaped slides.
  internal static func deck(slides: Int) -> Deck {
    Deck {
      for index in 0..<slides {
        slide(index: index)
      }
    }
  }

  /// One demo-shaped slide: title, code, caption, and a badge, with a
  /// transition and a build on the code block.
  private static func slide(index: Int) -> Slide {
    Slide {
      TextBox("Step \(index + 1)")
        .position(x: 120, y: 80)
        .frame(width: 1_200, height: 90)
        .fontSize(56)
        .bold()
      TextBox(code)
        .font("Menlo", size: 32)
        .position(x: 120, y: 240)
        .frame(width: 1_400, height: 420)
        .build(.in) {
          Dissolve().duration(0.5).trigger(.onClick)
        }
      TextBox("Authored by KeynoteKit — slide \(index + 1) of many")
        .position(x: 120, y: 720)
        .frame(width: 1_400, height: 70)
        .fontSize(28)
      TextBox("\(index + 1)")
        .position(x: 1_700, y: 940)
        .frame(width: 120, height: 70)
        .fontSize(28)
    }
    .transition(.magicMove.duration(1))
  }
}
