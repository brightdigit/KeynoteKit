//
//  ZStack.swift
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

/// A layout container that overlays its children, later ones drawing above earlier ones.
///
/// Children declare their own sizes with `.frame(width:height:)`; the stack
/// positions them and writes absolute coordinates at build time. Intrinsic
/// text measurement is issue #67, so an unsized child contributes zero
/// extent.
///
/// Unlike `VStack` and `HStack`, a depth stack does not size its children by
/// default — it has no cross axis, and SwiftUI's `ZStack` does not stretch
/// either. A child fills only where it asks to with `.frame(maxWidth:)` or
/// `.frame(maxHeight:)`.
public struct ZStack: SlideLayout {
  /// Cross-axis alignment of the children.
  internal var alignment: LayoutAlignment

  /// Fixed gap between adjacent children, in points.
  internal var spacing: Double

  /// The children, in declaration order.
  internal var children: [any SlideLayout]

  /// The stack's own frame, when declared.
  internal var frameSize: LayoutSize?

  /// Which axes expand into the bounds the parent proposes.
  internal var flexible: FlexibleAxes = .none

  /// The layout node this stack contributes.
  ///
  /// A declared frame becomes the node's own bounds, which is what gives a
  /// nested ``Spacer`` slack to divide. Without one the stack sizes to its
  /// children and spacers collapse.
  public var layoutNode: any LayoutNode {
    StackNode(
      axis: .depth,
      alignment: alignment,
      spacing: spacing,
      children: children.map(\.layoutNode),
      frame: frameSize,
      flexible: flexible
    )
  }

  /// Creates a stack.
  public init(
    alignment: HorizontalAlignment = .leading,
    spacing: Double = 0,
    @SlideItemsBuilder content: () -> [any SlideLayout]
  ) {
    self.alignment = alignment.node
    self.spacing = spacing
    self.children = content()
    self.frameSize = nil
  }

  /// Bounds the stack, letting either axis fill the proposed bounds.
  ///
  /// A filling axis gives nested `Spacer`s the parent's slack to divide.
  public func frame(maxWidth: FlexibleExtent? = nil, maxHeight: FlexibleExtent? = nil) -> ZStack {
    var stack = self
    stack.flexible = FlexibleAxes(
      width: maxWidth?.isFilling ?? stack.flexible.width,
      height: maxHeight?.isFilling ?? stack.flexible.height
    )
    stack.frameSize = frameSize.combined(width: maxWidth, height: maxHeight)
    return stack
  }

  /// Bounds the stack, which is what lets Spacer claim slack.
  public func frame(width: Double, height: Double) -> ZStack {
    var stack = self
    stack.frameSize = LayoutSize(width: width, height: height)
    return stack
  }
}
