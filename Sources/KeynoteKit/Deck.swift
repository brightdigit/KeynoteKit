//
//  Deck.swift
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

import Foundation

/// A Keynote presentation to be written to disk.
///
/// v0.1.0 authors decks by *template surgery*: a base `.key` document is
/// unpacked, mutated, and repacked. Writing therefore always happens relative
/// to a ``KeynoteTemplate``, which defaults to the minimal blank-theme template
/// bundled with this package.
///
/// ```swift
/// try Deck().write(to: url)                                  // bundled template
/// try Deck().write(to: url, basedOn: KeynoteTemplate(contentsOf: myTheme))
/// ```
///
/// Slide content is not modelled yet — that is the authoring API, tracked
/// separately. This type currently establishes the write entry point and its
/// `basedOn:` parameter, which must exist from day one so the primary API does
/// not change shape once content lands.
public struct Deck: Sendable {
  /// Creates an empty deck.
  public init() {}

  /// Writes the deck to disk, authored from a base template.
  ///
  /// The deck is produced by copying `template` and applying this deck's
  /// content to it. With no content modelled yet, the result is the template
  /// document verbatim.
  ///
  /// - Parameters:
  ///   - url: Destination for the `.key` document. Any existing file at this
  ///     location is replaced.
  ///   - template: Base document to author from. Defaults to
  ///     ``KeynoteTemplate/bundled``.
  /// - Throws: ``TemplateError/bundledResourceMissing`` if the default template
  ///   cannot be located, or a `CocoaError` if the template cannot be read or
  ///   the destination cannot be written.
  public func write(
    to url: URL,
    basedOn template: KeynoteTemplate = .bundled
  ) throws {
    try template.data().write(to: url, options: .atomic)
  }
}
