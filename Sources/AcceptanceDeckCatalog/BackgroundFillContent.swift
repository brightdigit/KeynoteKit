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
/// Green means:
/// - slide 1: a dark panel behind light text — the code-panel treatment the
///   demo deck (#56) needs; the text is legible, so the fill is painted
///   underneath, not on top
/// - slide 2: two filled boxes and one unfilled box side by side; the
///   unfilled box shows the slide background, proving the fill is opt-in
/// - slide 3: fill composed with vertical alignment and columns — the other
///   two shape-style properties — all three visibly applied at once
/// - slide 4: a semi-transparent fill over a filled neighbor, showing alpha
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
    compositionSlide
    alphaSlide
  }

  /// A dark panel with light text — the #56 code-panel treatment.
  private var codePanelSlide: Slide {
    Slide {
      TextBox("dark panel, light text")
        .position(x: 120, y: 80)
        .frame(width: 900, height: 70)
        .fontSize(40)
      TextBox("func render() {\n  deck.write(to: url)\n}")
        .background(Self.panel)
        .foregroundColor(Self.onPanel)
        .font("Menlo", size: 44)
        .position(x: 120, y: 220)
        .frame(width: 1_000, height: 320)
    }
  }

  /// Filled, filled, and unfilled boxes: the fill must be opt-in.
  private var optInSlide: Slide {
    Slide {
      TextBox("filled")
        .background(Color(red: 0.85, green: 0.25, blue: 0.2))
        .foregroundColor(Self.onPanel)
        .position(x: 100, y: 200)
        .frame(width: 460, height: 260)
        .fontSize(40)
      TextBox("filled")
        .background(Color(red: 0.15, green: 0.45, blue: 0.75))
        .foregroundColor(Self.onPanel)
        .position(x: 640, y: 200)
        .frame(width: 460, height: 260)
        .fontSize(40)
      TextBox("NOT filled")
        .position(x: 1_180, y: 200)
        .frame(width: 460, height: 260)
        .fontSize(40)
    }
  }

  /// Fill composed with the other two shape-style properties.
  private var compositionSlide: Slide {
    Slide {
      TextBox("fill + bottom alignment")
        .background(Self.panel)
        .foregroundColor(Self.onPanel)
        .verticalAlignment(.bottom)
        .position(x: 100, y: 100)
        .frame(width: 700, height: 700)
        .fontSize(36)
      TextBox("FILL + COLUMNS " + Self.filler)
        .background(Color(red: 0.18, green: 0.3, blue: 0.22))
        .foregroundColor(Self.onPanel)
        .columns(2, gap: 41.25)
        .position(x: 900, y: 100)
        .frame(width: 900, height: 700)
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
