//
//  TitleSlide.swift
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

/// The deck's opening slide.
///
/// Spacers above and below centre the pair without naming a y offset, and
/// neither box names a width — the `VStack` fills the padded canvas, and
/// each child fills the stack.
internal struct TitleSlide: SlideContent {
  internal var body: some SlideContent {
    Slide {
      VStack(spacing: 40) {
        Spacer()
        TextBox("KeynoteKit")
          .frame(height: 120)
          .fontSize(DemoStyle.titleSize)
          .bold()
        TextBox("Authored from Swift — no Keynote required to write")
          .frame(height: 80)
          .fontSize(DemoStyle.subtitleSize)
        Spacer()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(DemoStyle.margin)
    }
  }

  /// Creates the slide.
  internal init() {}
}
