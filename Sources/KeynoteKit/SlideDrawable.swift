//
//  SlideDrawable.swift
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

/// A drawable on a slide — text or image — before z-order sorting.
public enum SlideDrawable: Sendable {
  /// A text item.
  case text(TextBox)

  /// An image item.
  case image(Image)

  /// Layer order used for sorting into `drawablesZOrder`.
  internal var zIndex: Int {
    switch self {
    case .text(let text): text.zIndex ?? 0
    case .image(let image): image.zIndex ?? 0
    }
  }

  /// Builds attached to this drawable.
  internal var builds: [BuildEffectConfiguration] {
    switch self {
    case .text(let text): text.builds
    case .image(let image): image.builds
    }
  }

  /// Action build attached to this drawable.
  internal var action: MotionPath? {
    switch self {
    case .text(let text): text.action
    case .image(let image): image.action
    }
  }
}
