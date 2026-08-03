//
//  PaddedNode.swift
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

/// A layout node insetting its child on each edge.
public struct PaddedNode: LayoutNode {
  /// The insets applied around ``child``.
  internal var insets: EdgeInsets

  /// The wrapped node.
  internal var child: any LayoutNode

  /// The child's extent grown by the insets.
  public var size: LayoutSize {
    let inner = child.size
    return LayoutSize(
      width: inner.width + insets.leading + insets.trailing,
      height: inner.height + insets.top + insets.bottom
    )
  }

  /// Creates a padded node.
  public init(insets: EdgeInsets, child: any LayoutNode) {
    self.insets = insets
    self.child = child
  }

  /// Shrinks the bounds and offsets the origin by the leading insets.
  public func resolve(in bounds: LayoutSize?, origin: LayoutPoint?) -> [any SlideDrawable] {
    let inner = bounds.map {
      LayoutSize(
        width: $0.width - insets.leading - insets.trailing,
        height: $0.height - insets.top - insets.bottom
      )
    }
    let moved = origin?.offset(deltaX: insets.leading, deltaY: insets.top)
    return child.resolve(in: inner, origin: moved)
  }
}
