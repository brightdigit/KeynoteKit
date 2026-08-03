//
//  LeafNode.swift
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

/// A layout node wrapping one drawable.
public struct LeafNode: LayoutNode {
  /// The wrapped drawable.
  internal var drawable: any SlideDrawable

  /// The drawable's authored extent, with an unset axis reported as zero.
  ///
  /// There is no number to advance by until intrinsic measurement (#67), so
  /// an unsized child contributes nothing along the stack's axis.
  public var size: LayoutSize {
    let authored = drawable.authoredSize
    return LayoutSize(width: authored.width ?? 0, height: authored.height ?? 0)
  }

  /// Creates a leaf.
  public init(drawable: any SlideDrawable) {
    self.drawable = drawable
  }

  /// Positions the drawable, or leaves it alone when nothing is placing it.
  ///
  /// A `nil` origin is what keeps existing decks working: every drawable
  /// placed with `.position(x:y:)` and no enclosing stack must survive this
  /// pass untouched.
  public func resolve(in bounds: LayoutSize?, origin: LayoutPoint?) -> [any SlideDrawable] {
    guard let origin else {
      return [drawable]
    }
    return [drawable.positioned(x: origin.x, y: origin.y)]
  }
}
