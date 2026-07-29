//
//  Element.swift
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

/// Wire constants for the four Snappy block elements.
///
/// The low two bits of a tag byte select the element type; the remaining six
/// carry a length or, for one-byte-offset copies, the offset's high bits.
internal enum Element {
  /// Tag selector for a literal run.
  internal static let literalTag: UInt8 = 0x00

  /// Tag selector for a copy with a one-byte offset operand.
  internal static let copy1Tag: UInt8 = 0x01

  /// Tag selector for a copy with a two-byte offset operand.
  internal static let copy2Tag: UInt8 = 0x02

  /// Literal selectors at or above this value store their length in the
  /// following one to four bytes instead of inline.
  internal static let firstExtendedLiteralSelector = 60

  /// Largest literal length encodable inline in the tag byte.
  internal static let maximumInlineLiteralLength = 60

  /// Shortest run a copy element can express.
  internal static let minimumCopyLength = 4

  /// Longest run a copy element can express.
  internal static let maximumCopyLength = 64

  /// Longest run a one-byte-offset copy can express.
  internal static let maximumCopy1Length = 11

  /// Largest offset a one-byte-offset copy can reach back.
  internal static let maximumCopy1Offset = 2_047

  /// Largest offset a two-byte-offset copy can reach back.
  internal static let maximumCopy2Offset = 65_535
}
