//
//  Slide.swift
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

/// One slide: drawables in declaration order, plus an optional transition.
public struct Slide: SlideContent, Sendable {
  /// The slide canvas a top-level stack lays out within, in points.
  ///
  /// Matches the bundled template's 1920x1080 slide size, so a stack given
  /// no explicit frame still has bounds for ``Spacer`` to divide.
  internal static let canvas = LayoutSize(width: 1_920, height: 1_080)

  /// The slide's drawables, in declaration order (before z-index sort).
  internal var items: [any SlideDrawable]

  /// The slide's transition, when set.
  internal var slideTransition: SlideTransition?

  /// `Slide` is primitive content: it composes to itself.
  public var body: SlideGroup {
    SlideGroup(slides: [self])
  }

  /// Creates a slide from its layout elements.
  ///
  /// Stacks, spacers, and padding resolve **here**, at build time: the tree
  /// is walked once and each drawable comes out carrying the absolute
  /// `x`/`y` the surgeon writes. `items` is therefore the same flat,
  /// absolutely-positioned list it has always been, and nothing downstream
  /// — lowering, z-order, builds, the archive — knows layout exists (#65).
  ///
  /// The slide canvas is the resolution bounds, so a top-level ``Spacer``
  /// divides the full slide.
  public init(@SlideItemsBuilder content: () -> [any SlideLayout]) {
    let elements = content()
    self.items = elements.flatMap { element in
      element.layoutNode.resolve(in: Self.canvas, origin: nil)
    }
    self.slideTransition = nil
  }

  /// Sets the slide's transition.
  ///
  /// - Parameter transition: The transition style and timing.
  /// - Returns: The modified slide.
  public func transition(_ transition: SlideTransition) -> Slide {
    var slide = self
    slide.slideTransition = transition
    return slide
  }
}
