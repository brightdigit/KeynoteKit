//
//  ArchiveSurgeryError.swift
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

/// Failures while applying authored content to a base document.
package enum ArchiveSurgeryError: Error, Equatable, Sendable {
  /// The base document has no `KN.ShowArchive`.
  case missingShowArchive

  /// A slide-tree reference did not resolve.
  case missingSlideRecord(identifier: UInt64)

  /// The spec's slide count differs from the base document's.
  case slideCountMismatch(expected: Int, found: Int)

  /// A slide's item count differs from the base slide's drawable count.
  case drawableCountMismatch(slideIndex: Int, items: Int, drawables: Int)

  /// A build's target index is out of range for its slide.
  case targetOutOfRange(slideIndex: Int, targetIndex: Int)

  /// The slide has no transition block to set a direction on.
  case missingTransitionPath(slideIndex: Int)

  /// No `TSP.PackageMetadata` component matches the slide.
  case missingSlideComponent(slideIdentifier: UInt64)

  /// The component's locator disagrees with the slide identifier.
  case unexpectedComponentLocator(String)

  /// The document violates a write invariant; opening it would crash
  /// Keynote (`research/findings/write_backend_bisect.md`).
  case invariantViolation(String)
}
