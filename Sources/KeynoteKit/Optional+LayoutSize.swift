//
//  Optional+LayoutSize.swift
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

extension Optional where Wrapped == LayoutSize {
  /// Folds new per-axis extents into an existing frame.
  ///
  /// A filling axis contributes no number, so it leaves whatever was there
  /// (usually nothing) — the resolve pass substitutes the proposed bounds
  /// for that axis instead. The frame stays `nil` until some axis is
  /// actually fixed, which is what keeps an unframed stack sizing to its
  /// children.
  internal func combined(
    width: FlexibleExtent?,
    height: FlexibleExtent?
  ) -> LayoutSize? {
    let resolvedWidth = width?.fixedValue ?? self?.width
    let resolvedHeight = height?.fixedValue ?? self?.height
    guard resolvedWidth != nil || resolvedHeight != nil else {
      return nil
    }
    return LayoutSize(width: resolvedWidth ?? 0, height: resolvedHeight ?? 0)
  }
}
