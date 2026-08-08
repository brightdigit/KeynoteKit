//
//  StackNode+Flexible.swift
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

extension StackNode {
  /// The stack's declared extent, `nil` per axis when it declared none.
  ///
  /// An unframed stack authored nothing, so it fills its parent's cross axis
  /// like any other child. Lives here rather than in `StackNode.swift` only
  /// to keep that file under the file-length limit.
  public var authoredSize: DrawableSize {
    DrawableSize(width: frame?.width, height: frame?.height)
  }

  /// The space this stack lays its children out in.
  ///
  /// Per-axis, because a stack may fill one axis and fix the other: a
  /// filling axis adopts the proposal, a declared frame wins otherwise, and
  /// an unframed stack falls back to the proposal so top-level spacers keep
  /// working.
  internal func containerSize(proposedBy bounds: LayoutSize?) -> LayoutSize? {
    guard !flexible.isEmpty, let bounds else {
      return frame ?? bounds
    }
    let declared = frame
    return LayoutSize(
      width: flexible.width ? bounds.width : (declared?.width ?? bounds.width),
      height: flexible.height ? bounds.height : (declared?.height ?? bounds.height)
    )
  }

  /// What to propose to a child, given its intrinsic size.
  ///
  /// The cross axis is the container's whenever the child has no extent of
  /// its own there — that default is what lets a box span the stack without
  /// naming a width. An authored extent always wins, so cross-axis alignment
  /// stays meaningful.
  ///
  /// The main axis is opt-in only, and shared: a filling child takes
  /// `mainShare`, the slack left after fixed children and any `Spacer`s have
  /// taken theirs. Spacers are settled first, so the two features compose —
  /// a `Spacer` still wins the space it claims, and a filling child divides
  /// only what remains. Defaulting the main axis too would put every child
  /// in competition for that same slack.
  internal func proposal(
    for child: any LayoutNode,
    intrinsic: LayoutSize,
    crossExtent: Double,
    mainShare: Double,
    bounds: LayoutSize?
  ) -> LayoutSize {
    let axes = child.flexibleAxes
    switch axis {
    case .vertical:
      return LayoutSize(
        width: crossProposal(
          intrinsic: intrinsic.width,
          crossExtent: crossExtent,
          authored: child.authoredSize.width,
          fills: axes.width,
          bounds: bounds
        ),
        height: axes.height ? mainShare : intrinsic.height
      )
    case .horizontal:
      return LayoutSize(
        width: axes.width ? mainShare : intrinsic.width,
        height: crossProposal(
          intrinsic: intrinsic.height,
          crossExtent: crossExtent,
          authored: child.authoredSize.height,
          fills: axes.height,
          bounds: bounds
        )
      )
    case .depth:
      return intrinsic
    }
  }

  /// A child's cross-axis extent: the container's when it fills, else its own.
  ///
  /// Filling requires `bounds`. Without them ``crossExtent(sizes:bounds:)``
  /// reports the widest sibling — zero when every sibling is unauthored too —
  /// and filling from that would silently resize drawables to nothing. An
  /// unbounded stack therefore leaves the axis at its intrinsic extent.
  private func crossProposal(
    intrinsic: Double,
    crossExtent: Double,
    authored: Double?,
    fills: Bool,
    bounds: LayoutSize?
  ) -> Double {
    guard fills || (authored == nil && bounds != nil) else {
      return intrinsic
    }
    return crossExtent
  }

  /// Each main-axis filling child's share of the leftover space.
  ///
  /// Mirrors ``StackNode/spacerShare(sizes:bounds:)`` but runs after it:
  /// spacers take their slack first, and filling children split what is
  /// left. Zero without bounds, so an unbounded stack leaves a filling
  /// child at its intrinsic extent rather than producing a `nan`.
  internal func fillingMainShare(
    sizes: [LayoutSize],
    bounds: LayoutSize?,
    spacerShare: Double
  ) -> Double {
    let filling = children.indices.filter { index in
      let axes = children[index].flexibleAxes
      return axis == .vertical ? axes.height : axes.width
    }
    guard !filling.isEmpty, let bounds else {
      return 0
    }
    let spacerCount = children.count { $0 is SpacerNode }
    let gaps = Double(max(0, children.count - 1)) * spacing
    let fixed = children.indices
      .filter { !filling.contains($0) && !(children[$0] is SpacerNode) }
      .reduce(0.0) { total, index in
        total + (axis == .vertical ? sizes[index].height : sizes[index].width)
      }
    let available = axis == .vertical ? bounds.height : bounds.width
    let claimed = fixed + gaps + spacerShare * Double(spacerCount)
    return max(0, available - claimed) / Double(filling.count)
  }
}
