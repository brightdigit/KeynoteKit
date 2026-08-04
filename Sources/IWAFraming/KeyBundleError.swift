//
//  KeyBundleError.swift
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

/// Errors thrown when reading or writing a `.key` zip container.
///
/// The reader is deliberately narrow: it accepts exactly the archives
/// Keynote's own writer produces — every entry `STORED`, no zip64 — and
/// throws a typed error for anything else rather than guessing. If Keynote
/// ever emits `DEFLATED` or zip64, the recorded exit is to revisit the
/// depend-vs-vendor survey, not to grow this reader.
public enum KeyBundleError: Error, Equatable, Sendable {
  /// No end-of-central-directory record was found in the input.
  case notAZipArchive

  /// A structure ran past the end of the input; `context` names which.
  case truncatedArchive(context: String)

  /// An entry uses a compression method other than `STORED`.
  ///
  /// Measured across all 30 committed `.key` files: 1,604 of 1,604 entries
  /// are `STORED`. Anything else is not a Keynote document this library
  /// understands.
  case unsupportedCompressionMethod(UInt16, path: String)

  /// An entry's body did not match its recorded CRC-32.
  case checksumMismatch(path: String)

  /// The archive uses zip64 structures, which Keynote documents never need.
  case zip64Unsupported

  /// Two entries share the same path.
  case duplicateEntryPath(String)
}
