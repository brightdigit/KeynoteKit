//
//  ZipEndOfCentralDirectory.swift
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

/// The end-of-central-directory record that terminates every zip archive.
internal struct ZipEndOfCentralDirectory {
  /// The little-endian signature `PK\x05\x06`.
  internal static let signature: UInt32 = 0x0605_4B50

  /// The fixed byte count of the record, excluding the trailing comment.
  internal static let fixedByteCount = 22

  /// The number of central directory records.
  internal var entryCount: Int

  /// The offset of the first central directory record.
  internal var centralDirectoryOffset: Int

  /// Locates and parses the record by scanning backward from the end.
  ///
  /// The scan tolerates a trailing archive comment (up to 64 KiB, per the
  /// format's 16-bit comment length). Keynote never writes one, but a
  /// backward scan is the only correct way to find the record regardless.
  internal static func locate(in buffer: ZipBytes) throws -> ZipEndOfCentralDirectory {
    let earliest = max(0, buffer.bytes.count - fixedByteCount - 65_535)
    var offset = buffer.bytes.count - fixedByteCount
    while offset >= earliest {
      if buffer.readUInt32(at: offset) == signature {
        return try parse(from: buffer, at: offset)
      }
      offset -= 1
    }
    throw KeyBundleError.notAZipArchive
  }

  /// Parses the record at `offset`, rejecting multi-disk and zip64 markers.
  private static func parse(from buffer: ZipBytes, at offset: Int) throws
    -> ZipEndOfCentralDirectory
  {
    let diskNumber = buffer.readUInt16(at: offset + 4)
    let entryCount = buffer.readUInt16(at: offset + 10)
    let directoryOffset = buffer.readUInt32(at: offset + 16)
    guard diskNumber == 0 else {
      throw KeyBundleError.truncatedArchive(context: "multi-disk archive")
    }
    guard entryCount < 0xFFFF, directoryOffset < 0xFFFF_FFFF else {
      throw KeyBundleError.zip64Unsupported
    }
    // `Int(exactly:)` keeps the untrusted offset from trapping on 32-bit
    // platforms, where it cannot address real data anyway.
    guard let centralDirectoryOffset = Int(exactly: directoryOffset) else {
      throw KeyBundleError.truncatedArchive(context: "central directory offset")
    }
    return ZipEndOfCentralDirectory(
      entryCount: entryCount,
      centralDirectoryOffset: centralDirectoryOffset
    )
  }

  /// Appends the record to `output`.
  internal static func append(
    to output: inout ZipBytes,
    entryCount: Int,
    centralDirectoryOffset: Int,
    centralDirectoryByteCount: Int
  ) {
    output.appendUInt32(signature)
    output.appendUInt16(0)  // this disk number
    output.appendUInt16(0)  // central directory start disk
    output.appendUInt16(entryCount)  // entries on this disk
    output.appendUInt16(entryCount)  // entries total
    output.appendUInt32(UInt32(centralDirectoryByteCount))
    output.appendUInt32(UInt32(centralDirectoryOffset))
    output.appendUInt16(0)  // comment length
  }
}
