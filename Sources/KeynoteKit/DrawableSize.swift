//
//  DrawableSize.swift
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

/// A drawable's authored size, where either axis may be unset.
///
/// The optional-component sibling of ``LayoutNode/Size``: `nil` in an axis
/// means the drawable inherits the template placeholder's extent there,
/// rather than declaring one. A stack has no number to advance by in that
/// case, so it treats the axis as zero — see ``LayoutNode/Size``.
public struct DrawableSize: Equatable, Sendable {
  /// Authored width in points, or `nil` to inherit the template's.
  public var width: Double?

  /// Authored height in points, or `nil` to inherit the template's.
  public var height: Double?

  /// Creates an authored size.
  public init(width: Double?, height: Double?) {
    self.width = width
    self.height = height
  }
}
