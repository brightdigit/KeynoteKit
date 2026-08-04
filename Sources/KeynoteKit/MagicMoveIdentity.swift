//
//  MagicMoveIdentity.swift
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

/// What Keynote's Magic Move matcher compares two drawables by.
///
/// Splits the comparison into the two failures the DSL reports separately:
/// a ``kind`` mismatch is a type error, an equal kind with differing
/// ``content`` is a content error. Keeping them apart preserves the
/// distinction the pairwise enum switch used to make.
public struct MagicMoveIdentity: Equatable, Sendable {
  /// The drawable's type tag — `"text"`, `"image"`.
  ///
  /// A string rather than an enum so a drawable kind added outside this
  /// module can report one without editing a closed set.
  public var kind: String

  /// The matchable content: a text box's joined paragraphs, an image's
  /// bytes. Geometry is deliberately excluded — differing geometry is the
  /// motion Magic Move animates, not a mismatch.
  public var content: MagicMoveContent

  /// Creates an identity.
  public init(kind: String, content: MagicMoveContent) {
    self.kind = kind
    self.content = content
  }
}
