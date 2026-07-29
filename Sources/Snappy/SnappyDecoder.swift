//
//  SnappyDecoder.swift
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

/// Decodes the Snappy block format.
///
/// The block body is a stream of elements, each introduced by a tag byte whose
/// low two bits select literal, or a copy with a one-, two-, or four-byte
/// offset. Every bounds check throws rather than trapping.
internal enum SnappyDecoder {
  /// Decodes a complete block.
  ///
  /// - Parameter input: The compressed block, including its length preamble.
  /// - Returns: The uncompressed bytes.
  /// - Throws: A ``SnappyError`` if the block is malformed.
  internal static func decode(_ input: UnsafeBufferPointer<UInt8>) throws -> [UInt8] {
    var index = 0
    let expectedCount = try Varint.decode(from: input, at: &index)
    guard expectedCount <= Snappy.maximumBlockSize else {
      throw SnappyError.blockTooLarge
    }

    var output = [UInt8]()
    output.reserveCapacity(expectedCount)

    while index < input.count {
      let tag = input[index]
      if tag & 0x03 == Element.literalTag {
        try appendLiteral(tag: tag, input: input, index: &index, output: &output)
      } else {
        try appendCopy(tag: tag, input: input, index: &index, output: &output)
      }
    }

    guard output.count == expectedCount else {
      throw SnappyError.lengthMismatch
    }
    return output
  }

  /// Reads a little-endian integer of `width` bytes.
  private static func readInteger(
    from input: UnsafeBufferPointer<UInt8>,
    at index: inout Int,
    width: Int
  ) throws -> Int {
    guard index + width <= input.count else {
      throw SnappyError.truncatedInput
    }
    var value = 0
    for offset in 0..<width {
      value |= Int(input[index + offset]) << (8 * offset)
    }
    index += width
    return value
  }

  /// Appends a literal element's bytes to `output`.
  private static func appendLiteral(
    tag: UInt8,
    input: UnsafeBufferPointer<UInt8>,
    index: inout Int,
    output: inout [UInt8]
  ) throws {
    let selector = Int(tag >> 2)
    index += 1

    // Selectors 60...63 store the length in the following 1...4 bytes;
    // anything lower is the length itself.
    let length: Int
    if selector < Element.firstExtendedLiteralSelector {
      length = selector + 1
    } else {
      let width = selector - Element.firstExtendedLiteralSelector + 1
      length = try readInteger(from: input, at: &index, width: width) + 1
    }

    guard index + length <= input.count else {
      throw SnappyError.truncatedInput
    }
    output.append(contentsOf: UnsafeBufferPointer(rebasing: input[index..<(index + length)]))
    index += length
  }

  /// Appends a copy element by replaying earlier output.
  private static func appendCopy(
    tag: UInt8,
    input: UnsafeBufferPointer<UInt8>,
    index: inout Int,
    output: inout [UInt8]
  ) throws {
    let (length, offset) = try readCopyOperands(tag: tag, input: input, index: &index)

    guard offset > 0, offset <= output.count else {
      throw SnappyError.invalidCopyOffset
    }

    // Overlapping copies are legal and are how runs are encoded, so this must
    // stay a byte-at-a-time replay rather than a bulk move.
    var source = output.count - offset
    for _ in 0..<length {
      output.append(output[source])
      source += 1
    }
  }

  /// Decodes the length and offset of a copy element.
  private static func readCopyOperands(
    tag: UInt8,
    input: UnsafeBufferPointer<UInt8>,
    index: inout Int
  ) throws -> (length: Int, offset: Int) {
    let selector = tag & 0x03
    index += 1

    guard selector != Element.copy1Tag else {
      // 3-bit length biased by 4, plus the tag's high 3 bits as offset bits 8...10.
      let length = Int((tag >> 2) & 0x07) + 4
      let high = Int(tag >> 5) << 8
      let low = try readInteger(from: input, at: &index, width: 1)
      return (length, high | low)
    }

    let width = selector == Element.copy2Tag ? 2 : 4
    let length = Int(tag >> 2) + 1
    let offset = try readInteger(from: input, at: &index, width: width)
    return (length, offset)
  }
}
