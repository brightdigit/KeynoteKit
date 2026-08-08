//
//  StackNode.swift
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

/// A layout node arranging children along an axis.
public struct StackNode: LayoutNode {
  /// The axis children advance along.
  internal var axis: LayoutAxis

  /// Cross-axis alignment.
  internal var alignment: LayoutAlignment

  /// Main-axis alignment.
  internal var mainAlignment: LayoutAlignment

  /// Fixed gap between adjacent children, in points.
  internal var spacing: Double

  /// The children, in declaration order.
  internal var children: [any LayoutNode]

  /// The stack's declared frame, when it has one.
  ///
  /// Bounds the stack for spacer distribution and cross-axis alignment.
  /// `nil` means the stack sizes to its children.
  internal var frame: LayoutSize?

  /// Which axes expand into the bounds the parent proposes.
  internal var flexible: FlexibleAxes = .none

  /// The stack's extent: its frame when declared, else the sum along its
  /// axis plus spacing, by the widest child across it. A depth stack takes
  /// the maximum on both axes, since its children share one origin.
  public var size: LayoutSize {
    if let frame {
      return frame
    }
    let sizes = children.map(\.size)
    let gaps = Double(max(0, children.count - 1)) * spacing
    switch axis {
    case .vertical:
      return LayoutSize(
        width: sizes.map(\.width).max() ?? 0,
        height: sizes.map(\.height).reduce(0, +) + gaps
      )
    case .horizontal:
      return LayoutSize(
        width: sizes.map(\.width).reduce(0, +) + gaps,
        height: sizes.map(\.height).max() ?? 0
      )
    case .depth:
      return LayoutSize(
        width: sizes.map(\.width).max() ?? 0,
        height: sizes.map(\.height).max() ?? 0
      )
    }
  }

  /// Which axes expand into the bounds the parent proposes.
  public var flexibleAxes: FlexibleAxes { flexible }

  /// Creates a stack node.
  public init(
    axis: LayoutAxis,
    alignment: LayoutAlignment,
    mainAlignment: LayoutAlignment = .leading,
    spacing: Double,
    children: [any LayoutNode],
    frame: LayoutSize?,
    flexible: FlexibleAxes = .none
  ) {
    self.axis = axis
    self.alignment = alignment
    self.mainAlignment = mainAlignment
    self.spacing = spacing
    self.children = children
    self.frame = frame
    self.flexible = flexible
  }

  /// Positions the children and recurses into each.
  ///
  /// A declared frame wins over inherited bounds — that is what gives a
  /// nested spacer slack to divide. A flexible axis inverts that: it takes
  /// the proposed bounds instead, which is what `.frame(maxWidth:
  /// .infinity)` means.
  public func resolve(in bounds: LayoutSize?, origin: LayoutPoint?) -> [any SlideDrawable] {
    let container = containerSize(proposedBy: bounds)
    guard axis != .depth else {
      return resolveOverlaid(in: container, origin: origin)
    }
    return resolveLinear(in: container, origin: origin)
  }

  /// Advances children along the axis, aligning each across it.
  private func resolveLinear(
    in bounds: LayoutSize?,
    origin: LayoutPoint?
  ) -> [any SlideDrawable] {
    let base = origin ?? LayoutPoint(x: 0, y: 0)
    let sizes = children.map(\.size)
    let share = spacerShare(sizes: sizes, bounds: bounds)
    let crossExtent = self.crossExtent(sizes: sizes, bounds: bounds)
    let mainShare = fillingMainShare(sizes: sizes, bounds: bounds, spacerShare: share)
    var resolved: [any SlideDrawable] = []
    var offset: Double = initialMainOffset(in: bounds, sizes: sizes)
    for (index, child) in children.enumerated() {
      if index > 0 {
        offset += spacing
      }
      if child is SpacerNode {
        offset += share
        continue
      }
      let childSize = proposal(
        for: child,
        intrinsic: sizes[index],
        crossExtent: crossExtent,
        mainShare: mainShare,
        bounds: bounds
      )
      let cross = crossOffset(
        childExtent: axis == .vertical ? childSize.width : childSize.height,
        containerExtent: crossExtent
      )
      let childOrigin =
        axis == .vertical
        ? base.offset(deltaX: cross, deltaY: offset)
        : base.offset(deltaX: offset, deltaY: cross)
      resolved += child.resolve(in: childSize, origin: childOrigin)
      offset += axis == .vertical ? childSize.height : childSize.width
    }
    return resolved
  }

  /// Overlays children on one origin, aligning each across both axes.
  ///
  /// Depth order maps onto the existing `zIndex`, which the lowering pass
  /// already sorts by — declaration order breaks ties, so later children
  /// draw above earlier ones without extra bookkeeping.
  private func resolveOverlaid(
    in bounds: LayoutSize?,
    origin: LayoutPoint?
  ) -> [any SlideDrawable] {
    let base = origin ?? LayoutPoint(x: 0, y: 0)
    let container = bounds ?? size
    var resolved: [any SlideDrawable] = []
    for child in children where !(child is SpacerNode) {
      // A depth stack has no main axis, so a flexible child can take the
      // container on both axes without competing with a spacer for slack.
      let axes = child.flexibleAxes
      let intrinsic = child.size
      let childSize = LayoutSize(
        width: axes.width ? container.width : intrinsic.width,
        height: axes.height ? container.height : intrinsic.height
      )
      let deltaX = crossOffset(childExtent: childSize.width, containerExtent: container.width)
      let deltaY = crossOffset(childExtent: childSize.height, containerExtent: container.height)
      resolved += child.resolve(in: childSize, origin: base.offset(deltaX: deltaX, deltaY: deltaY))
    }
    return resolved
  }
}
