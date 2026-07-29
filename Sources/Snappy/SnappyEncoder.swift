//
//  SnappyEncoder.swift
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

/// Encodes the Snappy block format.
///
/// Matching uses a single-probe hash table over four-byte sequences — the
/// scheme the reference encoder uses. Output only has to be *valid*, so an
/// unprofitable match is simply emitted as literals.
internal enum SnappyEncoder {
  /// Number of slots in the match hash table. A power of two so the hash can
  /// mask instead of dividing.
  private static let tableSize = 1 << 14

  /// Encodes `input` as a complete block.
  ///
  /// - Parameter input: The bytes to compress.
  /// - Returns: A Snappy block including its length preamble.
  internal static func encode(_ input: UnsafeBufferPointer<UInt8>) -> [UInt8] {
    var output = [UInt8]()
    output.reserveCapacity(Snappy.maximumCompressedLength(for: input.count))
    Varint.encode(input.count, into: &output)

    guard input.count >= Element.minimumCopyLength else {
      Literal.emit(from: input, range: 0..<input.count, into: &output)
      return output
    }

    var table = [Int32](repeating: -1, count: tableSize)
    var nextLiteral = 0
    var index = 0
    let lastMatchStart = input.count - Element.minimumCopyLength

    while index <= lastMatchStart {
      let candidate = probe(input: input, index: index, table: &table)
      guard let candidate, let length = extend(input: input, index: index, candidate: candidate)
      else {
        index += 1
        continue
      }

      Literal.emit(from: input, range: nextLiteral..<index, into: &output)
      Copy.emit(length: length, offset: index - candidate, into: &output)
      index += length
      nextLiteral = index
    }

    Literal.emit(from: input, range: nextLiteral..<input.count, into: &output)
    return output
  }

  /// Looks up — and records — the four bytes at `index`, returning a usable
  /// earlier position if one is stored.
  private static func probe(
    input: UnsafeBufferPointer<UInt8>,
    index: Int,
    table: inout [Int32]
  ) -> Int? {
    let key = hash(input: input, index: index)
    let stored = Int(table[key])
    table[key] = Int32(index)

    guard stored >= 0, index - stored <= Element.maximumCopy2Offset else {
      return nil
    }
    return stored
  }

  /// Confirms a candidate really matches and measures how far it runs.
  ///
  /// - Returns: The match length, or `nil` if it is too short to be worth a
  ///   copy element.
  private static func extend(
    input: UnsafeBufferPointer<UInt8>,
    index: Int,
    candidate: Int
  ) -> Int? {
    let limit = min(input.count - index, Element.maximumCopyLength)
    guard limit >= Element.minimumCopyLength else {
      return nil
    }

    var length = 0
    while length < limit, input[candidate + length] == input[index + length] {
      length += 1
    }

    guard length >= Element.minimumCopyLength else {
      return nil
    }
    return length
  }

  /// Hashes the four bytes starting at `index` into a table slot.
  private static func hash(input: UnsafeBufferPointer<UInt8>, index: Int) -> Int {
    let word =
      UInt32(input[index])
      | UInt32(input[index + 1]) << 8
      | UInt32(input[index + 2]) << 16
      | UInt32(input[index + 3]) << 24
    return Int((word &* 0x1E35_A7BD) >> (32 - 14))
  }
}
