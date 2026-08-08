//
//  DemoStyle.swift
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

/// Values shared across the demo's slides, so a new slide inherits the
/// deck's look instead of re-deriving it.
internal enum DemoStyle {
  /// The margin every slide insets its content by, in points.
  ///
  /// The only geometry constant the demo needs. A stack child fills the
  /// cross axis by default, so a box spans the padded canvas without naming
  /// a width, and the 1920x1080 size is never restated. The heights slides
  /// carry are real author intent — text cannot measure itself yet (#67).
  internal static let margin = 80.0

  /// Point size for a slide's headline.
  internal static let titleSize = 72.0

  /// Point size for a section heading below a headline.
  internal static let headingSize = 48.0

  /// Point size for supporting text under a headline.
  internal static let subtitleSize = 36.0

  /// Point size for body copy.
  internal static let bodySize = 28.0
}
