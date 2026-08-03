//
//  LowerableDrawable.swift
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

/// A drawable the writer knows how to lower.
///
/// Separate from ``SlideDrawable`` because the result type is package-level:
/// a public protocol cannot require it. In practice only `TextBox` and
/// `Image` conform, and ``Deck`` rejects anything else at lowering time
/// rather than silently dropping it.
package protocol LowerableDrawable {
  /// Lowers this drawable into the writer's closed representation.
  ///
  /// Each type builds its own case, keeping the field-by-field construction
  /// next to the type that owns those fields.
  func lowered() -> AuthoredSlide.DrawableItem
}

extension SlideDrawable {
  /// This drawable lowered, or `nil` when the writer has no case for it.
  ///
  /// Only `TextBox` and `Image` conform to ``LowerableDrawable`` today. A
  /// drawable kind added outside this module would land here as `nil`, and
  /// ``Deck`` throws rather than dropping it — a silently missing drawable
  /// is exactly the class of bug the acceptance decks exist to catch.
  package var loweredItem: AuthoredSlide.DrawableItem? {
    (self as? any LowerableDrawable)?.lowered()
  }
}
