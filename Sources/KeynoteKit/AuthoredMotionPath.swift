//
//  AuthoredMotionPath.swift
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

/// An Action build's motion path: straight or bezier segments authored as an
/// editable bezier path source, mirroring the spec shape the Python backend
/// consumed (`research/findings/build_out.md`: a default Move is a 50 pt
/// two-node horizontal segment).
package struct AuthoredMotionPath: Equatable, Sendable {
  /// One path node; `sharp` nodes carry identical in/node/out points.
  package struct Point: Equatable, Sendable {
    /// The node's x coordinate.
    package var x: Double

    /// The node's y coordinate.
    package var y: Double

    /// Creates a point.
    package init(x: Double, y: Double) {
      self.x = x
      self.y = y
    }
  }

  /// One path node; absent control handles coincide with `point` (sharp).
  package struct Node: Equatable, Sendable {
    /// The node's position.
    package var point: Point

    /// The incoming segment's control handle, when curved.
    package var controlIn: Point?

    /// The outgoing segment's control handle, when curved.
    package var controlOut: Point?

    /// Creates a node.
    package init(point: Point, controlIn: Point? = nil, controlOut: Point? = nil) {
      self.point = point
      self.controlIn = controlIn
      self.controlOut = controlOut
    }
  }

  /// The path's natural width in points.
  package var naturalWidth: Double

  /// The path's natural height in points.
  package var naturalHeight: Double

  /// The path's nodes.
  package var nodes: [Node]

  /// Creates a motion path from full bezier nodes.
  package init(naturalWidth: Double, naturalHeight: Double, nodes: [Node]) {
    self.naturalWidth = naturalWidth
    self.naturalHeight = naturalHeight
    self.nodes = nodes
  }

  /// Creates a sharp polyline path.
  package init(naturalWidth: Double, naturalHeight: Double, points: [Point]) {
    self.init(
      naturalWidth: naturalWidth,
      naturalHeight: naturalHeight,
      nodes: points.map { Node(point: $0) }
    )
  }
}
