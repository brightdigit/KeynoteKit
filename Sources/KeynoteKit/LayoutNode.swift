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

/// A node in the compile-time layout tree.
///
/// This is a **build-time** structure. Drawables already carry absolute
/// `x`/`y` and the surgeon already writes those numbers, so a stack is a
/// pure source-level convenience: the tree resolves once and emits exactly
/// the positions an author could have typed by hand. Nothing here reaches
/// the archive.
///
/// A protocol rather than a closed enum so a layout kind can be added
/// without editing a central switch — the resolve logic lives on each node
/// type instead of in one dispatcher.
public protocol LayoutNode: Sendable {
  /// The node's laid-out extent.
  ///
  /// A bounds-free property, so sizing is a bottom-up fold over authored
  /// values. An axis that fills reports its intrinsic extent here and picks
  /// up the real number in ``resolve(in:origin:)``, where bounds exist.
  var size: LayoutSize { get }

  /// Which axes expand into the bounds a parent proposes.
  ///
  /// Defaulted to ``FlexibleAxes/none``, so a node that never opts in keeps
  /// its pre-existing sizing behavior.
  var flexibleAxes: FlexibleAxes { get }

  /// The extent the author actually named, where either axis may be unset.
  ///
  /// Distinct from ``size``, which flattens an unset axis to zero and so
  /// cannot tell "authored zero" from "never authored". A stack needs that
  /// distinction to fill the cross axis by default: an axis left `nil` here
  /// takes the container's extent, while an authored one is left alone.
  var authoredSize: DrawableSize { get }

  /// Resolves this node into absolutely-positioned drawables.
  ///
  /// - Parameters:
  ///   - bounds: The space to lay out within. Only ``SpacerNode`` consumes
  ///     it: with no bounds a stack has no slack, so spacers collapse.
  ///   - origin: The node's top-left corner in slide coordinates, or `nil`
  ///     when nothing is positioning this node — a drawable declared
  ///     outside any stack keeps the position it authored.
  /// - Returns: One drawable per leaf, in declaration order, which the
  ///   lowering pass relies on to break `zIndex` ties.
  func resolve(in bounds: LayoutSize?, origin: LayoutPoint?) -> [any SlideDrawable]
}

extension LayoutNode {
  /// Nodes opt into filling; the default keeps intrinsic sizing.
  public var flexibleAxes: FlexibleAxes { .none }

  /// Nodes author nothing by default, so both axes are free to fill.
  public var authoredSize: DrawableSize { DrawableSize(width: nil, height: nil) }
}
