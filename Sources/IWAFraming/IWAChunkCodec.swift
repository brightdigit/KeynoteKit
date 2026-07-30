//
//  IWAChunkCodec.swift
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

import Snappy

/// Apple's `.iwa` chunk framing over the Snappy block codec.
///
/// Every `Index/*.iwa` member of a `.key` bundle is a sequence of chunks, each
/// a 4-byte header — a `0x00` type byte followed by a 3-byte little-endian
/// *compressed* length — and then a stock Snappy block. There is no `sNaPpY`
/// stream identifier and no CRC-32C; the layout was measured across every
/// fixture in `research/findings/snappy_survey.md` §1.
///
/// This layer speaks only `Snappy`'s public block API. The decompressed
/// archive stream it produces is decoded by `TSPArchiveStream` in
/// `KeynoteKitProtobuf`.
public enum IWAChunkCodec {
  /// The exact uncompressed size at which Apple's writer splits chunks.
  ///
  /// Measured, not assumed: five fixture chunks sit exactly on this boundary
  /// and none exceed it.
  public static let maximumUncompressedChunkCount = 65_536

  /// The number of bytes in a chunk header.
  private static let headerByteCount = 4

  /// Decodes a framed `.iwa` file into its archive stream.
  ///
  /// - Parameter framed: The full contents of an `.iwa` member.
  /// - Returns: The concatenated decompressed payloads of every chunk.
  /// - Throws: ``IWAChunkError`` if the framing is malformed, or `SnappyError`
  ///   if a chunk's Snappy payload is.
  public static func decode(_ framed: [UInt8]) throws -> [UInt8] {
    var payload: [UInt8] = []
    var index = 0
    while index < framed.count {
      let chunk = try nextChunk(in: framed, at: &index)
      let block = try Snappy.decompress(chunk)
      payload.append(contentsOf: block)
    }
    return payload
  }

  /// Encodes an archive stream into a framed `.iwa` file.
  ///
  /// Splits `payload` at ``maximumUncompressedChunkCount`` exactly as Apple's
  /// writer does, compresses each piece as one Snappy block, and prefixes each
  /// with its chunk header. Encoding is total: compression never fails, and a
  /// 64 KiB block's worst-case compressed size fits the 24-bit length field
  /// with room to spare.
  ///
  /// - Parameter payload: The archive stream to frame.
  /// - Returns: The framed `.iwa` bytes; empty input produces empty output.
  public static func encode(_ payload: [UInt8]) -> [UInt8] {
    var framed: [UInt8] = []
    var start = 0
    while start < payload.count {
      let end = min(start + maximumUncompressedChunkCount, payload.count)
      let block = Snappy.compress(Array(payload[start..<end]))
      framed.append(0x00)
      framed.append(UInt8(block.count & 0xFF))
      framed.append(UInt8((block.count >> 8) & 0xFF))
      framed.append(UInt8((block.count >> 16) & 0xFF))
      framed.append(contentsOf: block)
      start = end
    }
    return framed
  }

  /// Reads one chunk header at `index` and returns its compressed payload,
  /// advancing `index` past the chunk.
  private static func nextChunk(in framed: [UInt8], at index: inout Int) throws -> [UInt8] {
    guard framed.count - index >= headerByteCount else {
      throw IWAChunkError.truncatedHeader(offset: index)
    }
    guard framed[index] == 0x00 else {
      throw IWAChunkError.unsupportedChunkType(framed[index], offset: index)
    }
    let length =
      Int(framed[index + 1])
      | (Int(framed[index + 2]) << 8)
      | (Int(framed[index + 3]) << 16)
    index += headerByteCount
    guard framed.count - index >= length else {
      throw IWAChunkError.truncatedChunk(expected: length, available: framed.count - index)
    }
    let chunk = Array(framed[index..<(index + length)])
    index += length
    return chunk
  }
}
