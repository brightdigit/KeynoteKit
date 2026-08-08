//
//  FlexibleAxes.swift
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

/// Which axes of a drawable expand into the proposed bounds.
///
/// Carried alongside the authored `width`/`height` rather than replacing
/// them: an unset axis still means "inherit the template placeholder", and
/// a fixed axis still reports its constant to the bottom-up size fold. Only
/// a filling axis defers to the bounds handed down at resolve time.
public struct FlexibleAxes: Equatable, Sendable {
  /// Neither axis fills — the default for every authored drawable.
  public static let none = FlexibleAxes(width: false, height: false)

  /// Whether the width adopts the proposed bounds.
  public var width: Bool

  /// Whether the height adopts the proposed bounds.
  public var height: Bool

  /// Whether either axis fills.
  internal var isEmpty: Bool {
    !width && !height
  }

  /// Creates a flexibility pair.
  public init(width: Bool, height: Bool) {
    self.width = width
    self.height = height
  }
}
