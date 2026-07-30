//
//  SlideContent.swift
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

/// A composable piece of a deck, mirroring SwiftUI at the slide level.
///
/// Conform custom types and compose them inside ``Deck``; the primitive
/// content is ``Slide``.
public protocol SlideContent {
  /// The composed content type.
  associatedtype Body: SlideContent

  /// The content this value composes to. Apply `@SlideBuilder` in
  /// conformances that compose multiple pieces.
  var body: Body { get }
}

extension Never: SlideContent {
  /// `Never` is the terminal body of primitive content.
  public var body: Never {
    fatalError("Never has no body")
  }
}

extension SlideContent {
  /// The flattened slides this content resolves to.
  internal var resolvedSlides: [Slide] {
    if let slide = self as? Slide {
      return [slide]
    }
    if let group = self as? SlideGroup {
      return group.slides
    }
    if Body.self == Never.self {
      return []
    }
    return body.resolvedSlides
  }
}
