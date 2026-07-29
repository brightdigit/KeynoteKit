//
//  KeynoteTemplate.swift
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

/// The base `.key` document a deck is authored from.
///
/// v0.1.0 authors decks by *template surgery* — unpack a base document, mutate
/// it, repack it — so every write needs a base. ``bundled`` is the minimal
/// blank-theme template shipped inside this package; ``init(contentsOf:)``
/// takes a document the caller supplies instead.
///
/// ## Redistribution
///
/// ``bundled`` is derived from Keynote's `21_basicwhite` theme, so a small
/// amount of Apple-authored content ships inside this package: a 2.5 KB
/// `Data/st-*.jpg`, a 50 KB `DocumentStylesheet.iwa` of theme styling, and
/// three `documentResourceLocator` entries that resolve against Keynote's
/// installed theme bundle at open time. The template was reduced from 458 KB by
/// removing the theme's slide layouts through Keynote's own UI, which
/// *minimizes* this exposure but does not eliminate it. Callers who must ship
/// no Apple-authored theme content at all should supply their own base document
/// via ``init(contentsOf:)``.
public struct KeynoteTemplate: Sendable {
  /// File name of the template resource inside the package bundle.
  private static let resourceName = "blank"

  /// File extension of the template resource inside the package bundle.
  private static let resourceExtension = "key"

  /// The minimal blank-theme template bundled with KeynoteKit.
  ///
  /// This is the default base for ``Deck/write(to:basedOn:)``. See the type's
  /// redistribution note for what Apple-authored content it carries.
  public static let bundled = KeynoteTemplate(source: .bundled)

  /// Where this template's bytes come from.
  private let source: Source

  /// Creates a template backed by a caller-supplied `.key` document.
  ///
  /// The document is read lazily, when the template is first used — this
  /// initializer does not validate that `url` exists or is a readable `.key`.
  ///
  /// - Parameter url: Location of the `.key` document to author from.
  public init(contentsOf url: URL) {
    self.source = .url(url)
  }

  /// Creates a template from an explicit source.
  ///
  /// - Parameter source: Where the template's bytes come from.
  private init(source: Source) {
    self.source = source
  }

  /// Reads the template's raw `.key` bytes.
  ///
  /// The returned data is the document verbatim — a `.key` is a zip archive,
  /// and callers depend on its bytes being untransformed.
  ///
  /// - Returns: The complete `.key` document.
  /// - Throws: ``TemplateError/bundledResourceMissing`` if the bundled resource
  ///   cannot be located, or a `CocoaError` if the document cannot be read.
  public func data() throws -> Data {
    try Data(contentsOf: self.url())
  }

  /// Resolves the on-disk location of the template document.
  ///
  /// - Returns: A file URL for the `.key` document.
  /// - Throws: ``TemplateError/bundledResourceMissing`` if the bundled resource
  ///   is not present in `Bundle.module`.
  public func url() throws -> URL {
    switch self.source {
    case .url(let url):
      return url

    case .bundled:
      guard
        let url = Bundle.module.url(
          forResource: Self.resourceName,
          withExtension: Self.resourceExtension
        )
      else {
        throw TemplateError.bundledResourceMissing
      }
      return url
    }
  }
}

extension KeynoteTemplate {
  /// Where a template's bytes come from.
  private enum Source: Sendable {
    /// The `blank.key` resource inside `Bundle.module`.
    case bundled

    /// A `.key` document at a caller-supplied location.
    case url(URL)
  }
}
