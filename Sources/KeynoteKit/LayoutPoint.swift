//
//  LayoutPoint.swift
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

/// A position in slide coordinates, in points.
///
/// The peer of ``LayoutSize``: the resolve pass takes a size for bounds and
/// a point for origin, so both are named types rather than one struct and
/// one tuple.
public struct LayoutPoint: Equatable, Sendable {
  /// Distance from the slide's left edge, in points.
  public var x: Double

  /// Distance from the slide's top edge, in points.
  public var y: Double

  /// Creates a point.
  public init(x: Double, y: Double) {
    self.x = x
    self.y = y
  }

  /// This point moved by the given deltas.
  internal func offset(deltaX: Double, deltaY: Double) -> LayoutPoint {
    LayoutPoint(x: x + deltaX, y: y + deltaY)
  }
}
