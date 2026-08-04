//
//  ZipCentralDirectoryRecord.swift
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

/// One central directory record: the authoritative description of an entry.
///
/// The reader trusts these fields — not the local header — for method, sizes,
/// and CRC, which sidesteps bit-3 data descriptors entirely.
internal struct ZipCentralDirectoryRecord {
  /// The little-endian signature `PK\x01\x02`.
  internal static let signature: UInt32 = 0x0201_4B50

  /// The fixed byte count before the variable-length trailing fields.
  internal static let fixedByteCount = 46

  /// The entry path, decoded as UTF-8.
  internal var path: String

  /// The compression method; `0` is `STORED`.
  internal var method: UInt16

  /// The recorded CRC-32 of the entry body.
  internal var crc: UInt32

  /// The compressed size; equals the body length for `STORED` entries.
  internal var compressedByteCount: Int

  /// The uncompressed size.
  internal var uncompressedByteCount: Int

  /// The offset of the entry's local file header.
  internal var localHeaderOffset: Int

  /// The total record width, including name, extra, and comment fields.
  internal var recordByteCount: Int

  /// Parses the record at `offset`.
  internal static func parse(
    from buffer: ZipBytes,
    at offset: Int
  ) throws -> ZipCentralDirectoryRecord {
    guard
      offset + fixedByteCount <= buffer.bytes.count,
      buffer.readUInt32(at: offset) == signature
    else {
      throw KeyBundleError.truncatedArchive(context: "central directory record")
    }
    let nameByteCount = buffer.readUInt16(at: offset + 28)
    let extraByteCount = buffer.readUInt16(at: offset + 30)
    let commentByteCount = buffer.readUInt16(at: offset + 32)
    let nameStart = offset + fixedByteCount
    guard nameStart + nameByteCount <= buffer.bytes.count else {
      throw KeyBundleError.truncatedArchive(context: "central directory entry name")
    }
    // `Int(exactly:)` keeps untrusted 32-bit size/offset fields from
    // trapping on 32-bit platforms; such values cannot address real data
    // there, so they are malformed by construction.
    guard
      let compressedByteCount = Int(exactly: buffer.readUInt32(at: offset + 20)),
      let uncompressedByteCount = Int(exactly: buffer.readUInt32(at: offset + 24)),
      let localHeaderOffset = Int(exactly: buffer.readUInt32(at: offset + 42))
    else {
      throw KeyBundleError.truncatedArchive(context: "central directory sizes")
    }
    return ZipCentralDirectoryRecord(
      path: String(
        decoding: buffer.bytes[nameStart..<(nameStart + nameByteCount)],
        as: UTF8.self
      ),
      method: UInt16(buffer.readUInt16(at: offset + 10)),
      crc: buffer.readUInt32(at: offset + 16),
      compressedByteCount: compressedByteCount,
      uncompressedByteCount: uncompressedByteCount,
      localHeaderOffset: localHeaderOffset,
      recordByteCount: fixedByteCount + nameByteCount + extraByteCount + commentByteCount
    )
  }

  /// Appends a `STORED` central directory record for `entry` to `output`.
  internal static func append(
    to output: inout ZipBytes,
    entry: KeyBundleEntry,
    crc: UInt32,
    localHeaderOffset: Int
  ) {
    output.appendUInt32(signature)
    output.appendUInt16(20)  // version made by
    output.appendUInt16(20)  // version needed: 2.0
    output.appendUInt16(0)  // general-purpose flags
    output.appendUInt16(0)  // method: STORED
    output.appendUInt16(0)  // modification time
    output.appendUInt16(0)  // modification date
    output.appendUInt32(crc)
    output.appendUInt32(UInt32(entry.body.count))  // compressed size
    output.appendUInt32(UInt32(entry.body.count))  // uncompressed size
    output.appendUInt16(Array(entry.path.utf8).count)
    output.appendUInt16(0)  // extra field length
    output.appendUInt16(0)  // comment length
    output.appendUInt16(0)  // disk number start
    output.appendUInt16(0)  // internal attributes
    output.appendUInt32(0)  // external attributes
    output.appendUInt32(UInt32(localHeaderOffset))
    output.append(contentsOf: Array(entry.path.utf8))
  }
}
