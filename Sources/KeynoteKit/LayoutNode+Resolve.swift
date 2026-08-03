//
//  LayoutNode+Resolve.swift
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

extension LayoutNode {
  /// A node's extent along both axes, in points.
  public struct Size: Equatable, Sendable {
    /// Width in points.
    public var width: Double

    /// Height in points.
    public var height: Double

    /// Creates a size.
    public init(width: Double, height: Double) {
      self.width = width
      self.height = height
    }
  }

  /// The node's laid-out size.
  ///
  /// A leaf reports its authored frame; an unsized axis reports **zero**,
  /// because there is no number to advance by until intrinsic measurement
  /// (#67) exists. A `Spacer` also reports zero — it claims slack during
  /// distribution rather than contributing a fixed extent.
  internal var size: Size {
    switch self {
    case .leaf(let drawable):
      let authored = drawable.authoredSize
      return Size(width: authored.width ?? 0, height: authored.height ?? 0)

    case .spacer:
      return Size(width: 0, height: 0)

    case .padded(let insets, let child):
      let inner = child.size
      return Size(
        width: inner.width + insets.leading + insets.trailing,
        height: inner.height + insets.top + insets.bottom
      )

    case .stack(let stack):
      return stack.frame ?? Self.stackSize(stack)
    }
  }

  /// Resolves the tree into absolutely-positioned drawables.
  ///
  /// - Parameters:
  ///   - bounds: The space this node lays out within. Only ``spacer``
  ///     consumes it: with no bounds, a stack has no slack to distribute
  ///     and spacers collapse to zero.
  ///   - origin: The node's top-left corner in slide coordinates.
  /// - Returns: One drawable per leaf, in declaration order. Declaration
  ///   order is preserved because the lowering pass uses it to break
  ///   `zIndex` ties.
  internal func resolve(
    in bounds: Size?,
    origin: (x: Double, y: Double)?
  ) -> [SlideDrawable] {
    switch self {
    case .leaf(let drawable):
      // A leaf outside any stack keeps the position it authored. Only a
      // stack repositions its children, so existing decks — every drawable
      // placed with `.position(x:y:)` — are untouched by this pass.
      guard let origin else {
        return [drawable]
      }
      return [drawable.positioned(x: origin.x, y: origin.y)]

    case .spacer:
      return []

    case .padded(let insets, let child):
      let inner = bounds.map {
        Size(
          width: $0.width - insets.leading - insets.trailing,
          height: $0.height - insets.top - insets.bottom
        )
      }
      let inset = origin.map { (x: $0.x + insets.leading, y: $0.y + insets.top) }
      return child.resolve(in: inner, origin: inset)

    case .stack(let stack):
      return Self.resolveStack(stack, in: stack.frame ?? bounds, origin: origin)
    }
  }
}
