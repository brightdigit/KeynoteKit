//
//  ZipLocalFileHeader.swift
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

/// A zip local file header, as read from or written before an entry's body.
///
/// Only the fields the `.key` reader needs are modeled. The parser trusts the
/// central directory for sizes (sidestepping bit-3 data descriptors) and uses
/// the local header solely to locate where the body starts.
internal struct ZipLocalFileHeader {
  /// The little-endian signature `PK\x03\x04`.
  internal static let signature: UInt32 = 0x0403_4B50

  /// The fixed byte count before the variable-length name and extra fields.
  internal static let fixedByteCount = 30

  /// The length of the entry name in bytes.
  internal var nameByteCount: Int

  /// The length of the extra field in bytes.
  internal var extraByteCount: Int

  /// Parses the local header at `offset`.
  ///
  /// - Throws: ``KeyBundleError/truncatedArchive(context:)`` if the header
  ///   does not fit or its signature is wrong.
  internal static func parse(from buffer: ZipBytes, at offset: Int) throws -> ZipLocalFileHeader {
    guard
      offset >= 0,
      offset + fixedByteCount <= buffer.bytes.count,
      buffer.readUInt32(at: offset) == signature
    else {
      throw KeyBundleError.truncatedArchive(context: "local file header")
    }
    return ZipLocalFileHeader(
      nameByteCount: buffer.readUInt16(at: offset + 26),
      extraByteCount: buffer.readUInt16(at: offset + 28)
    )
  }

  /// Appends a `STORED` local header for `entry` to `output`.
  internal static func append(to output: inout ZipBytes, entry: KeyBundleEntry, crc: UInt32) {
    output.appendUInt32(signature)
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
    output.append(contentsOf: Array(entry.path.utf8))
  }

  /// The offset of the entry body: header start + fixed fields + name + extra.
  internal func bodyOffset(fromHeaderAt offset: Int) -> Int {
    offset + Self.fixedByteCount + nameByteCount + extraByteCount
  }
}
