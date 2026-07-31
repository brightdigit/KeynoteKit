//
//  MotionPath.swift
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

/// An Action build: the target travels a motion path.
///
/// v0.1.0 carries the full editable bezier path source; the default path is
/// the proven 50 pt two-node horizontal segment
/// (`research/findings/build_out.md`). Sharp polylines come from
/// ``init(points:)``; curved segments from ``init(nodes:)`` with control
/// handles on each ``Node``.
public struct MotionPath: Sendable {
  /// One point in path coordinates.
  public struct Point: Sendable, Equatable {
    internal var x: Double
    internal var y: Double

    /// Creates a point at (`x`, `y`).
    public init(x: Double, y: Double) {
      self.x = x
      self.y = y
    }
  }

  /// One path node: a position with optional bezier control handles.
  public struct Node: Sendable, Equatable {
    internal var position: Point
    internal var controlIn: Point?
    internal var controlOut: Point?

    /// Creates a node.
    ///
    /// Omitted control handles coincide with `position` — a sharp corner.
    /// Providing `controlIn`/`controlOut` curves the segments entering and
    /// leaving the node.
    public init(at position: Point, controlIn: Point? = nil, controlOut: Point? = nil) {
      self.position = position
      self.controlIn = controlIn
      self.controlOut = controlOut
    }
  }

  /// The path's nodes.
  internal var nodes: [Node]

  /// The path's natural size.
  internal var naturalWidth: Double

  /// The path's natural height.
  internal var naturalHeight: Double

  /// Seconds.
  internal var duration: Double = 1.0

  /// Seconds.
  internal var delay: Double = 0.0

  /// The start trigger.
  internal var trigger: BuildTrigger = .onClick

  /// Creates a sharp polyline path; the default is the proven 50 pt
  /// horizontal Move.
  public init(points: [Point] = [Point(x: 0, y: 0), Point(x: 50, y: 0)]) {
    self.init(nodes: points.map { Node(at: $0) })
  }

  /// Creates a path from full bezier nodes.
  public init(nodes: [Node]) {
    self.nodes = nodes
    let xs = nodes.flatMap { [$0.position.x, $0.controlIn?.x, $0.controlOut?.x].compactMap { $0 } }
    let ys = nodes.flatMap { [$0.position.y, $0.controlIn?.y, $0.controlOut?.y].compactMap { $0 } }
    // Natural size is the path's extent, not its maximum coordinate — a
    // leftward or offset path would otherwise claim a zero or inflated box.
    self.naturalWidth = (xs.max() ?? 0) - (xs.min() ?? 0)
    self.naturalHeight = (ys.max() ?? 0) - (ys.min() ?? 0)
  }

  /// Sets the action's duration in seconds.
  public func duration(_ seconds: Double) -> MotionPath {
    var path = self
    path.duration = seconds
    return path
  }

  /// Sets the action's delay in seconds.
  public func delay(_ seconds: Double) -> MotionPath {
    var path = self
    path.delay = seconds
    return path
  }

  /// Sets the action's start trigger.
  public func trigger(_ trigger: BuildTrigger) -> MotionPath {
    var path = self
    path.trigger = trigger
    return path
  }
}
