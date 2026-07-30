//
//  AuthoredSlide.swift
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

/// One slide's authored content, positionally matched to a base slide.
package struct AuthoredSlide: Equatable, Sendable {
  /// The number of text items the spec declares; must equal the base
  /// slide's `drawablesZOrder` count (drawable order is target order).
  package var itemCount: Int

  /// The slide transition's direction ordinal, when the spec sets one —
  /// the only transition field archive surgery touches.
  package var transitionDirection: UInt32?

  /// The slide's builds, in delivery order.
  package var builds: [AuthoredBuild]

  /// Creates a slide.
  package init(itemCount: Int, transitionDirection: UInt32? = nil, builds: [AuthoredBuild] = []) {
    self.itemCount = itemCount
    self.transitionDirection = transitionDirection
    self.builds = builds
  }
}
