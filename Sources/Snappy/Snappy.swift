//
//  Snappy.swift
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

/// The generic Snappy block codec.
///
/// This module implements the *block* format only — the varint length preamble
/// followed by literal and copy elements. It deliberately knows nothing about
/// any stream framing:
///
/// - The `sNaPpY` stream identifier, chunk headers, and CRC-32C checksums of
///   Snappy's standard framing format are **not** implemented here.
/// - Apple's `.iwa` framing, which uses this same block format under a
///   *different* chunk layout, lives in `IWAFraming`.
///
/// Keeping that seam clean is what lets this codec be swapped for an external
/// package later without touching callers.
///
/// ```swift
/// let compressed = Snappy.compress(Array("hello".utf8))
/// let original = try Snappy.decompress(compressed)
/// ```
public enum Snappy {
  /// Largest block this codec will encode or decode, in bytes.
  ///
  /// The format bounds a block's uncompressed length to 32 bits. Producers
  /// typically chunk well below that; Apple's `.iwa` writer uses 64 KiB.
  public static let maximumBlockSize = Int(UInt32.max)

  /// The worst-case encoded size for `count` bytes.
  ///
  /// Useful for sizing a destination buffer up front. The bound covers the
  /// length preamble plus the literal-tag overhead the format adds roughly
  /// every 60 bytes when the input is incompressible.
  ///
  /// - Parameter count: The uncompressed byte count.
  /// - Returns: The maximum number of bytes ``compress(_:)`` can produce.
  public static func maximumCompressedLength(for count: Int) -> Int {
    Varint.maximumEncodedWidth + count + (count / Element.maximumInlineLiteralLength) + 1
  }

  /// Compresses `input` into a Snappy block.
  ///
  /// Compression never fails: any input encodes, in the worst case entirely as
  /// literal elements.
  ///
  /// - Parameter input: The bytes to compress.
  /// - Returns: A block including its length preamble.
  public static func compress(_ input: [UInt8]) -> [UInt8] {
    input.withUnsafeBufferPointer(SnappyEncoder.encode)
  }

  /// Decompresses a Snappy block.
  ///
  /// - Parameter input: A block including its length preamble.
  /// - Returns: The original bytes.
  /// - Throws: A ``SnappyError`` if `input` is malformed. Malformed input never
  ///   traps, so this is safe to call on bytes read from a file.
  public static func decompress(_ input: [UInt8]) throws -> [UInt8] {
    try input.withUnsafeBufferPointer(SnappyDecoder.decode)
  }

  /// Reads the uncompressed length recorded in a block's preamble.
  ///
  /// Parses only the preamble, so it stays cheap on large blocks and can size a
  /// buffer before committing to a full decode.
  ///
  /// - Parameter input: A block including its length preamble.
  /// - Returns: The length the block claims to decode to.
  /// - Throws: ``SnappyError/invalidLengthPreamble`` if the preamble is
  ///   truncated or wider than 32 bits.
  public static func uncompressedLength(of input: [UInt8]) throws -> Int {
    try input.withUnsafeBufferPointer { buffer in
      var index = 0
      return try Varint.decode(from: buffer, at: &index)
    }
  }
}
