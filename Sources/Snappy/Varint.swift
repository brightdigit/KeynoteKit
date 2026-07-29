//
//  Varint.swift
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

/// Little-endian base-128 varint coding for the block length preamble.
///
/// A Snappy block opens with the uncompressed length encoded this way; the
/// value is bounded to 32 bits by the format.
internal enum Varint {
  /// Largest number of bytes a 32-bit varint can occupy.
  internal static let maximumEncodedWidth = 5

  /// Decodes a varint from `bytes` starting at `index`.
  ///
  /// - Parameters:
  ///   - bytes: The buffer to read from.
  ///   - index: The offset to start at; advanced past the varint on success.
  /// - Returns: The decoded value.
  /// - Throws: ``SnappyError/invalidLengthPreamble`` if the varint is
  ///   truncated, over-long, or wider than 32 bits.
  internal static func decode(
    from bytes: UnsafeBufferPointer<UInt8>,
    at index: inout Int
  ) throws -> Int {
    var result: UInt64 = 0
    var shift: UInt64 = 0

    while true {
      guard index < bytes.count, shift <= 28 else {
        throw SnappyError.invalidLengthPreamble
      }
      let byte = bytes[index]
      index += 1
      result |= UInt64(byte & 0x7F) << shift
      guard byte & 0x80 != 0 else { break }
      shift += 7
    }

    guard result <= UInt64(UInt32.max) else {
      throw SnappyError.invalidLengthPreamble
    }
    return Int(result)
  }

  /// Appends `value` to `output` as a varint.
  ///
  /// - Parameters:
  ///   - value: A non-negative value that fits in 32 bits.
  ///   - output: The buffer to append to.
  internal static func encode(_ value: Int, into output: inout [UInt8]) {
    var remaining = UInt32(truncatingIfNeeded: value)
    while remaining >= 0x80 {
      output.append(UInt8(remaining & 0x7F) | 0x80)
      remaining >>= 7
    }
    output.append(UInt8(remaining))
  }

  /// The number of bytes ``encode(_:into:)`` writes for `value`.
  ///
  /// - Parameter value: A non-negative value that fits in 32 bits.
  /// - Returns: The encoded width in bytes.
  internal static func encodedWidth(of value: Int) -> Int {
    var remaining = UInt32(truncatingIfNeeded: value)
    var width = 1
    while remaining >= 0x80 {
      remaining >>= 7
      width += 1
    }
    return width
  }
}
