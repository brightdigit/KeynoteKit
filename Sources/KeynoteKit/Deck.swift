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
private import IWAFraming

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
/// Slide content is composed with ``SlideBuilder``: each ``Slide`` holds
/// ``TextBox`` and ``Image`` drawables with builds, actions, transitions,
/// and formatting.
///
/// ```swift
/// let deck = Deck {
///   Slide {
///     TextBox("Title").build(.in) { Dissolve() }
///   }
///   .transition(.magicMove.duration(1))
/// }
/// ```
public struct Deck: Sendable {
  /// The deck's slides, in presentation order.
  internal var slides: [Slide]

  /// Creates an empty deck (writes the template verbatim).
  public init() {
    self.slides = []
  }

  /// Creates a deck from composed ``SlideContent``.
  public init(@SlideBuilder content: () -> SlideGroup) {
    self.slides = content().slides
  }

  /// Writes the deck to disk, authored from a base template.
  ///
  /// Authoring is template surgery and never requires a running Keynote:
  /// the template is unpacked, slides and text items are supplied by
  /// cloning template subtrees, builds and transitions are minted as
  /// archives, and the two SIGTRAP invariants are verified before the
  /// container is repacked. An empty deck writes the template verbatim.
  ///
  /// - Parameters:
  ///   - url: Destination for the `.key` document. Any existing file at this
  ///     location is replaced.
  ///   - template: Base document to author from. Defaults to
  ///     ``KeynoteTemplate/bundled``.
  /// - Throws: ``TemplateError`` for a missing template,
  ///   ``MagicMoveError`` for an unmatchable `magicId` pairing, an
  ///   `ArchiveSurgeryError` for a base-document mismatch or invariant
  ///   violation, or a `CocoaError` for filesystem failures.
  public func write(
    to url: URL,
    basedOn template: KeynoteTemplate = .bundled
  ) throws {
    try validateMagicMovePairs()
    guard !slides.isEmpty else {
      try template.data().write(to: url, options: .atomic)
      return
    }
    var bundle = try KeyBundle(contentsOfZip: Array(template.data()))
    var surgeon = try KeynoteArchiveSurgeon(bundle: bundle)
    var generator = SystemRandomNumberGenerator()
    try surgeon.author(authoredDeck(), into: &bundle, using: &generator)
    try Data(bundle.serializedZip()).write(to: url, options: .atomic)
  }
}
