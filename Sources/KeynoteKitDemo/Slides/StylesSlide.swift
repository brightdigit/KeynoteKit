//
//  StylesSlide.swift
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

/// Mixed character styling within one box: bold and italic runs, each with
/// its own color, sharing a single ``TextBox``.
internal struct StylesSlide: SlideContent {
  internal var body: some SlideContent {
    Slide {
      VStack(spacing: 20) {
        TextBox("Supports a variety of styles")
          .frame(height: 180)
          .fontSize(DemoStyle.titleSize)
        TextBox {
          Text("Bold").bold().foregroundColor(.init(green: 1.0))
          Text("Italics").italic().foregroundColor(.init(red: 1.0))
        }
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
