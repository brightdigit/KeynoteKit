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

/// One slide: text items in declaration order, plus an optional transition.
public struct Slide: SlideContent, Sendable {
  /// The slide's text items, in declaration order.
  internal var items: [Text]

  /// The slide's transition, when set.
  internal var slideTransition: SlideTransition?

  /// `Slide` is primitive content.
  public var body: Never {
    fatalError("Slide is primitive content")
  }

  /// Creates a slide from its text items.
  public init(@SlideItemsBuilder content: () -> [Text]) {
    self.items = content()
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
