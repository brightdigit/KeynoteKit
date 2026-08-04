//
//  EdgeInsets.swift
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

/// Per-edge insets in points, as applied by ``TextBox/padding(_:)`` and
/// friends.
public struct EdgeInsets: Equatable, Sendable {
  /// Inset from the top, in points.
  public var top: Double

  /// Inset from the leading (left) edge, in points.
  public var leading: Double

  /// Inset from the bottom, in points.
  public var bottom: Double

  /// Inset from the trailing (right) edge, in points.
  public var trailing: Double

  /// Creates insets, defaulting every unspecified edge to zero.
  public init(
    top: Double = 0,
    leading: Double = 0,
    bottom: Double = 0,
    trailing: Double = 0
  ) {
    self.top = top
    self.leading = leading
    self.bottom = bottom
    self.trailing = trailing
  }

  /// Creates uniform insets on all four edges.
  public init(_ all: Double) {
    self.init(top: all, leading: all, bottom: all, trailing: all)
  }
}
