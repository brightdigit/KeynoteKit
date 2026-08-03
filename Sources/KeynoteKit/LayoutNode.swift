//
//  LayoutNode.swift
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

/// The internal layout tree a slide's content builds before it resolves to
/// absolutely-positioned drawables (#65).
///
/// This is a **compile-time** structure. `SlideDrawable` already carries
/// absolute `x`/`y`, and the surgeon already writes those numbers, so a
/// stack is a pure source-level convenience: ``resolve(in:origin:)`` walks
/// the tree once and emits exactly the positions an author could have typed
/// by hand. Nothing here reaches the archive.
///
/// Children declare their own sizes with `.frame(width:height:)`. Intrinsic
/// text measurement — computing a box's natural size from font metrics — is
/// issue #67, split out because it is coupled to #52 (Keynote lays
/// placeholder text out at the layout master's width, ignoring the authored
/// frame).
public indirect enum LayoutNode: Sendable {
  /// A positioned drawable.
  case leaf(SlideDrawable)

  /// A stack of children along `axis`.
  case stack(Stack)

  /// Flexible space that divides a stack's slack between its neighbours.
  case spacer

  /// A child inset on each edge.
  case padded(insets: EdgeInsets, child: LayoutNode)

  /// A stack's configuration.
  public struct Stack: Sendable {
    /// The axis children advance along.
    public var axis: Axis

    /// Cross-axis alignment.
    public var alignment: Alignment

    /// Fixed gap between adjacent children, in points.
    public var spacing: Double

    /// The children, in declaration order.
    public var children: [LayoutNode]

    /// The stack's declared frame, when it has one.
    ///
    /// Bounds the stack for ``Spacer`` distribution and for cross-axis
    /// alignment. `nil` means the stack sizes to its children.
    public var frame: Size?
  }

  /// The axis a stack advances along.
  public enum Axis: Sendable {
    /// Children advance downward; `ZStack` overlays them instead.
    case vertical

    /// Children advance rightward.
    case horizontal

    /// Children share one origin and stack in z-order.
    case depth
  }

  /// Cross-axis alignment within a stack.
  public enum Alignment: Sendable {
    /// Leading edge — top for a horizontal stack, left for a vertical one.
    case leading

    /// Centred on the cross axis.
    case center

    /// Trailing edge.
    case trailing
  }
}
