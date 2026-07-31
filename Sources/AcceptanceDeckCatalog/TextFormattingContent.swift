//
//  TextFormattingContent.swift
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

/// Authored font / weight / color for the #37 / expanded #24 human pass.
package struct TextFormattingContent: SlideContent {
  package var body: some SlideContent {
    Slide {
      Text("Styled")
        .font("HelveticaNeue", size: 48)
        .bold()
        .italic()
        .foregroundColor(TextColor(red: 0.85, green: 0.15, blue: 0.1))
        .position(x: 160, y: 220)
        .frame(width: 480, height: 100)
      Text("Plain neighbor")
        .position(x: 160, y: 360)
        .frame(width: 400, height: 60)
    }
  }

  /// Creates the content.
  package init() {}
}
