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
  internal static func parse(from bytes: [UInt8], at offset: Int) throws -> ZipLocalFileHeader {
    guard
      offset >= 0,
      offset + fixedByteCount <= bytes.count,
      ZipBytes.readUInt32(bytes, offset) == signature
    else {
      throw KeyBundleError.truncatedArchive(context: "local file header")
    }
    return ZipLocalFileHeader(
      nameByteCount: ZipBytes.readUInt16(bytes, offset + 26),
      extraByteCount: ZipBytes.readUInt16(bytes, offset + 28)
    )
  }

  /// Appends a `STORED` local header for `entry` to `output`.
  internal static func append(to output: inout [UInt8], entry: KeyBundleEntry, crc: UInt32) {
    ZipBytes.appendUInt32(&output, signature)
    ZipBytes.appendUInt16(&output, 20)  // version needed: 2.0
    ZipBytes.appendUInt16(&output, 0)  // general-purpose flags
    ZipBytes.appendUInt16(&output, 0)  // method: STORED
    ZipBytes.appendUInt16(&output, 0)  // modification time
    ZipBytes.appendUInt16(&output, 0)  // modification date
    ZipBytes.appendUInt32(&output, crc)
    ZipBytes.appendUInt32(&output, UInt32(entry.body.count))  // compressed size
    ZipBytes.appendUInt32(&output, UInt32(entry.body.count))  // uncompressed size
    ZipBytes.appendUInt16(&output, Array(entry.path.utf8).count)
    ZipBytes.appendUInt16(&output, 0)  // extra field length
    output.append(contentsOf: Array(entry.path.utf8))
  }

  /// The offset of the entry body: header start + fixed fields + name + extra.
  internal func bodyOffset(fromHeaderAt offset: Int) -> Int {
    offset + Self.fixedByteCount + nameByteCount + extraByteCount
  }
}
