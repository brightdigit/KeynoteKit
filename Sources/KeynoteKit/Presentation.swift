//
//  Presentation.swift
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

/// A whole presentation, composed from ``SlideContent``.
///
/// The root of the content hierarchy, mirroring SwiftUI's `App` above `Scene`
/// and `View`: ``SlideContent`` composes, ``Slide`` is the primitive, and a
/// `Presentation` is the finished deck.
///
/// ```swift
/// struct MyTalk: Presentation {
///   var body: some SlideContent {
///     TitleSlide()
///     AgendaSlide()
///   }
/// }
///
/// try MyTalk().write(to: url)
/// ```
///
/// Conforming is what lets a type skip the `Deck { … }` wrapper. Flattening
/// composed content is internal to this module — ``SlideContent`` cannot walk
/// its own tree from outside — so without this protocol every author has to
/// write `Deck { MyContent() }` by hand.
///
/// Deliberately **no entry point**. SwiftUI's `App` owns `main()` because
/// launching an app has one right answer; writing a `.key` does not — output
/// path, verification, and whether to open Keynote afterward all belong to the
/// executable. Keep those in your own `@main`.
public protocol Presentation {
  /// The composed content type.
  associatedtype Body: SlideContent

  /// The slides this presentation composes, in presentation order.
  ///
  /// The builder is inferred in conformances, as with ``SlideContent/body``.
  @SlideBuilder var body: Body { get }

  /// The `KN.BuildArchive` count ``deck`` is expected to produce.
  ///
  /// A structural self-check gate for tools that write this presentation and
  /// reopen it. Defaults to `0`; override it when slides carry builds.
  var buildCount: Int { get }

  /// Creates the presentation.
  init()
}

extension Presentation {
  /// No builds unless a conformer says otherwise.
  public var buildCount: Int { 0 }

  /// The presentation as a deck, ready to write or inspect.
  ///
  /// The value rather than the action: tests and tooling need a ``Deck``
  /// without touching the filesystem. Use ``write(to:basedOn:)`` to write one.
  public var deck: Deck {
    Deck {
      body
    }
  }

  /// Writes the presentation to disk, authored from a base template.
  ///
  /// Forwards to ``Deck/write(to:basedOn:)`` — see it for the authoring model
  /// and the errors thrown.
  ///
  /// - Parameters:
  ///   - url: Destination for the `.key` document. Any existing file at this
  ///     location is replaced.
  ///   - template: Base document to author from. Defaults to
  ///     ``KeynoteTemplate/bundled``.
  /// - Throws: Whatever ``Deck/write(to:basedOn:)`` throws — a
  ///   ``TemplateError`` for a missing template, a ``MagicMoveError`` for an
  ///   unmatchable `magicId` pairing, an `ArchiveSurgeryError` for a
  ///   base-document mismatch or invariant violation, or a `CocoaError` for
  ///   filesystem failures.
  public func write(
    to url: URL,
    basedOn template: KeynoteTemplate = .bundled
  ) throws {
    try deck.write(to: url, basedOn: template)
  }
}
