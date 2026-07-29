//
//  SnappyError.swift
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

/// Errors thrown when decoding a malformed Snappy block.
///
/// Decoding never traps on bad input: every malformed-input path surfaces as
/// one of these cases. Callers decoding untrusted bytes can therefore recover
/// rather than crash.
public enum SnappyError: Error, Equatable, Sendable {
  /// The varint length preamble is missing, truncated, or exceeds 32 bits.
  case invalidLengthPreamble

  /// An element's operands run past the end of the compressed block.
  case truncatedInput

  /// A copy element referenced an offset of zero, or one reaching back further
  /// than the bytes decoded so far.
  case invalidCopyOffset

  /// The decoded output did not match the length declared in the preamble.
  case lengthMismatch

  /// The declared uncompressed length exceeds ``Snappy/Snappy/maximumBlockSize``.
  case blockTooLarge

  /// The supplied output buffer is smaller than the encoder's worst case.
  case insufficientBuffer
}
