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

  /// Which axes expand into the bounds a parent proposes.
  public var flexibleAxes: FlexibleAxes { drawable.flexibleAxes }

  /// The drawable's authored extent, with `nil` preserved per axis.
  public var authoredSize: DrawableSize { drawable.authoredSize }

  /// Creates a leaf.
  public init(drawable: any SlideDrawable) {
    self.drawable = drawable
  }

  /// Positions the drawable, sizing any axis the stack proposed an extent
  /// for, or leaves it alone when nothing is placing it.
  ///
  /// A `nil` origin is what keeps existing decks working: every drawable
  /// placed with `.position(x:y:)` and no enclosing stack must survive this
  /// pass untouched — including its authored size, so a filling axis with
  /// no stack around it stays as authored rather than snapping to zero.
  public func resolve(in bounds: LayoutSize?, origin: LayoutPoint?) -> [any SlideDrawable] {
    guard let origin else {
      return [drawable]
    }
    let placed = drawable.positioned(x: origin.x, y: origin.y)
    guard let bounds else {
      return [placed]
    }
    let authored = drawable.authoredSize
    return [
      placed.resized(
        width: adopted(bounds.width, authored: authored.width, fills: flexibleAxes.width),
        height: adopted(bounds.height, authored: authored.height, fills: flexibleAxes.height)
      )
    ]
  }

  /// The extent to write on one axis, or `nil` to leave it as authored.
  ///
  /// The stack has already narrowed its proposal: on an axis it chose not to
  /// fill, `proposed` is the child's own intrinsic extent, so writing it back
  /// is a no-op. The one case to refuse is a zero proposal on an unauthored
  /// axis — that means no fill happened, and `nil` must stay `nil` because
  /// the writer reads it as "inherit the template placeholder".
  private func adopted(_ proposed: Double, authored: Double?, fills: Bool) -> Double? {
    guard fills || authored == nil else {
      return nil
    }
    guard proposed > 0 else {
      return nil
    }
    return proposed
  }
}
