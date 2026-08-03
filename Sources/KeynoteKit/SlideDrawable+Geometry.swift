//
//  SlideDrawable+Geometry.swift
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

extension SlideDrawable {
  /// The drawable's authored size, when it declared one.
  ///
  /// `nil` in either axis means the drawable inherits the template
  /// placeholder's size. Stacks cannot lay such a child out — they have no
  /// number to advance by — so ``LayoutNode`` treats an unsized child as
  /// zero-extent along the stack's axis and documents the consequence.
  /// Intrinsic measurement is issue #67.
  internal var authoredSize: (width: Double?, height: Double?) {
    switch self {
    case .text(let text): (text.width, text.height)
    case .image(let image): (image.width, image.height)
    }
  }

  /// Returns a copy positioned at `x`, `y` in slide coordinates.
  ///
  /// The resolve pass calls this once per drawable after computing absolute
  /// positions; the surgeon then writes exactly these numbers, unchanged.
  internal func positioned(x: Double, y: Double) -> SlideDrawable {
    switch self {
    case .text(let text): .text(text.position(x: x, y: y))
    case .image(let image): .image(image.position(x: x, y: y))
    }
  }
}
