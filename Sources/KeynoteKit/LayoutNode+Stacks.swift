//
//  LayoutNode+Stacks.swift
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
  /// A stack's extent: the sum along its axis plus spacing, and the widest
  /// child across it. A depth stack takes the maximum on both axes, since
  /// its children share one origin.
  internal static func stackSize(_ stack: Stack) -> Size {
    let sizes = stack.children.map(\.size)
    let gaps = Double(max(0, stack.children.count - 1)) * stack.spacing
    switch stack.axis {
    case .vertical:
      return Size(
        width: sizes.map(\.width).max() ?? 0,
        height: sizes.map(\.height).reduce(0, +) + gaps
      )
    case .horizontal:
      return Size(
        width: sizes.map(\.width).reduce(0, +) + gaps,
        height: sizes.map(\.height).max() ?? 0
      )
    case .depth:
      return Size(
        width: sizes.map(\.width).max() ?? 0,
        height: sizes.map(\.height).max() ?? 0
      )
    }
  }

  /// Positions a stack's children and recurses into each.
  internal static func resolveStack(
    _ stack: Stack,
    in bounds: Size?,
    origin: (x: Double, y: Double)?
  ) -> [SlideDrawable] {
    guard stack.axis != .depth else {
      return resolveDepthStack(stack, in: bounds, origin: origin)
    }
    let base = origin ?? (x: 0, y: 0)
    let sizes = stack.children.map(\.size)
    let spacerShare = self.spacerShare(stack, sizes: sizes, bounds: bounds)
    let crossExtent = Self.crossExtent(stack, sizes: sizes, bounds: bounds)
    var resolved: [SlideDrawable] = []
    var offset: Double = 0
    for (index, child) in stack.children.enumerated() {
      if index > 0 {
        offset += stack.spacing
      }
      if case .spacer = child {
        offset += spacerShare
        continue
      }
      let childSize = sizes[index]
      let cross = Self.crossOffset(
        stack.alignment,
        childExtent: stack.axis == .vertical ? childSize.width : childSize.height,
        containerExtent: crossExtent
      )
      let childOrigin =
        stack.axis == .vertical
        ? (x: base.x + cross, y: base.y + offset)
        : (x: base.x + offset, y: base.y + cross)
      resolved += child.resolve(in: childSize, origin: childOrigin)
      offset += stack.axis == .vertical ? childSize.height : childSize.width
    }
    return resolved
  }

  /// Overlays a depth stack's children on one origin, aligning each across
  /// both axes. `ZStack` maps onto the existing `zIndex`, which the
  /// lowering pass already sorts by — declaration order breaks ties, so
  /// later children draw above earlier ones without extra bookkeeping.
  private static func resolveDepthStack(
    _ stack: Stack,
    in bounds: Size?,
    origin: (x: Double, y: Double)?
  ) -> [SlideDrawable] {
    let base = origin ?? (x: 0, y: 0)
    let sizes = stack.children.map(\.size)
    let container = bounds ?? stackSize(stack)
    var resolved: [SlideDrawable] = []
    for (index, child) in stack.children.enumerated() {
      if case .spacer = child {
        continue
      }
      let childSize = sizes[index]
      let x = crossOffset(
        stack.alignment,
        childExtent: childSize.width,
        containerExtent: container.width
      )
      let y = crossOffset(
        stack.alignment,
        childExtent: childSize.height,
        containerExtent: container.height
      )
      resolved += child.resolve(
        in: childSize,
        origin: (x: base.x + x, y: base.y + y)
      )
    }
    return resolved
  }

  /// Each spacer's share of a stack's leftover space.
  ///
  /// Returns zero for an unbounded stack: with no container extent there is
  /// no slack to divide, so a `Spacer` is a documented no-op rather than an
  /// error. Give the stack a `.frame(width:height:)` to make spacers act.
  private static func spacerShare(_ stack: Stack, sizes: [Size], bounds: Size?) -> Double {
    let spacerCount = stack.children.count { node in
      if case .spacer = node {
        return true
      }
      return false
    }
    guard spacerCount > 0, let bounds else {
      return 0
    }
    let gaps = Double(max(0, stack.children.count - 1)) * stack.spacing
    let used =
      stack.axis == .vertical
      ? sizes.map(\.height).reduce(0, +)
      : sizes.map(\.width).reduce(0, +)
    let available = stack.axis == .vertical ? bounds.height : bounds.width
    return max(0, available - used - gaps) / Double(spacerCount)
  }

  /// The container extent on the cross axis, used for alignment.
  private static func crossExtent(_ stack: Stack, sizes: [Size], bounds: Size?) -> Double {
    if let bounds {
      return stack.axis == .vertical ? bounds.width : bounds.height
    }
    let extents = stack.axis == .vertical ? sizes.map(\.width) : sizes.map(\.height)
    return extents.max() ?? 0
  }

  /// A child's offset on the cross axis for the given alignment.
  private static func crossOffset(
    _ alignment: Alignment,
    childExtent: Double,
    containerExtent: Double
  ) -> Double {
    switch alignment {
    case .leading: 0
    case .center: (containerExtent - childExtent) / 2
    case .trailing: containerExtent - childExtent
    }
  }
}
