//
//  IWAChunkError.swift
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

/// Errors thrown when parsing a malformed `.iwa` chunk stream.
///
/// Parsing never traps on bad input: every malformed-framing path surfaces as
/// one of these cases. Failures inside a chunk's Snappy payload surface as
/// `SnappyError` instead, rethrown untouched.
public enum IWAChunkError: Error, Equatable, Sendable {
  /// Fewer than four bytes remain where a chunk header was expected.
  case truncatedHeader(offset: Int)

  /// A chunk header's type byte was not `0x00`.
  ///
  /// Every chunk in every fixture `.iwa` uses type `0x00`; any other value
  /// means the input is not Apple chunk framing.
  case unsupportedChunkType(UInt8, offset: Int)

  /// A chunk's declared compressed length runs past the end of the input.
  case truncatedChunk(expected: Int, available: Int)
}
