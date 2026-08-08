//
//  DemoDeck.swift
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

/// The #56 showcase presentation: a living sample authored through the
/// public KeynoteKit DSL.
///
/// Today this is a **scaffold** that proves the product graph and write
/// path. The finished demo grows to 15–20 slides covering transitions,
/// builds, layout, syntax-highlighted code panels, and background fills.
/// See `Sources/KeynoteKitDemo/README.md`.
///
/// Write it with:
///
/// ```bash
/// swift run KeynoteKitDemoTool ~/Desktop/keynotekit-demo
/// ```
public struct DemoDeck: Presentation {
  /// The showcase deck, in presentation order.
  ///
  /// **This body is the slide order.** Each slide is a type in `Slides/`,
  /// so reordering the deck is moving a line here rather than moving a
  /// block of layout code. As the tutorial body lands, keep the entries
  /// grouped by section with a blank line and a comment between groups.
  ///
  /// A slide may resolve to nothing — ``ImageSlide`` does when its resource
  /// is missing — so entries stay unconditional and each slide owns the
  /// question of whether it can be built.
  public var body: some SlideContent {
    TitleSlide()
    StylesSlide()
    ImageSlide()
  }

  /// Creates the presentation.
  public init() {}
}
