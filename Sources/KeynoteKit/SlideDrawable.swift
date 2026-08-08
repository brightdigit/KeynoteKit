//
//  SlideDrawable.swift
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

/// Something that can be placed on a slide — text or an image today.
///
/// A protocol rather than a closed enum: the authoring surface is open, so
/// a drawable kind can be added without touching every site that handles
/// one. The *archive* surface stays closed — ``lowered()`` returns
/// ``AuthoredSlide/DrawableItem``, a package enum the surgeon switches on
/// exhaustively, because the writer genuinely must handle every case it can
/// receive.
///
/// Public so a layout node can vend one and a conformer outside this module
/// can be placed on a slide. Lowering into the writer's representation is
/// deliberately *not* a requirement here — it needs `AuthoredSlide`, which
/// is package-level — so it lives in a separate package protocol,
/// ``LowerableDrawable``, that only `TextBox` and `Image` satisfy.
public protocol SlideDrawable: Sendable {
  /// Layer order; higher draws above lower.
  ///
  /// Normalized: a drawable that declared none reports 0, so sorting never
  /// has to unwrap. Declaration order breaks ties.
  var layerOrder: Int { get }

  /// Builds attached to this drawable, in declaration order.
  var drawableBuilds: [BuildEffectConfiguration] { get }

  /// Action builds attached to this drawable, in declaration order.
  var drawableActions: [MotionPath] { get }

  /// The Magic Move pairing declaration, when present.
  var drawableMagicIdentifier: String? { get }

  /// The authored size, where either axis may be unset.
  var authoredSize: DrawableSize { get }

  /// Which axes expand into the bounds the parent proposes.
  ///
  /// Defaulted to ``FlexibleAxes/none`` so an existing conformer outside
  /// this module keeps compiling — a drawable that never opts in behaves
  /// exactly as it did before flexible frames existed.
  var flexibleAxes: FlexibleAxes { get }

  /// The drawable's current position in slide coordinates.
  var authoredPosition: LayoutPoint { get }

  /// What Keynote's Magic Move matcher compares two drawables by.
  ///
  /// The format stores no object correspondence
  /// (`research/findings/magic_move_correspondence.md`) — matching is a
  /// runtime heuristic keyed on type and content. Two drawables can morph
  /// only if their identities are equal, so this stands in for the
  /// pairwise type-and-content check a closed enum would switch on.
  var magicMoveIdentity: MagicMoveIdentity { get }

  /// Returns a copy positioned at `x`, `y` in slide coordinates.
  func positioned(x: Double, y: Double) -> any SlideDrawable

  /// Returns a copy sized to `width` by `height`, in points.
  ///
  /// The counterpart to ``positioned(x:y:)`` for the fill path: it is the
  /// one place a drawable's extent originates from inherited bounds rather
  /// than an authored value. A `nil` axis leaves that axis untouched, so
  /// filling one axis never disturbs the other.
  func resized(width: Double?, height: Double?) -> any SlideDrawable
}

extension SlideDrawable {
  /// Drawables opt into filling; the default is to keep authored extents.
  public var flexibleAxes: FlexibleAxes { .none }
}
