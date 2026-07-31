//
//  ZipArchive.swift
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

/// The `STORED`-only zip reader and writer behind ``KeyBundle``.
///
/// Scope is exactly what Keynote's own writer produces: every entry `STORED`,
/// single disk, no zip64, no directory entries. Anything outside that throws
/// a ``KeyBundleError`` rather than being tolerated.
internal struct ZipArchive: Sendable {
  /// The shared default archive codec.
  internal static let `default` = ZipArchive()

  private init() {}

  /// Parses `bytes` into entries, in central directory order.
  internal func entries(from bytes: [UInt8]) throws -> [KeyBundleEntry] {
    let buffer = ZipBytes(bytes)
    let directoryEnd = try ZipEndOfCentralDirectory.locate(in: buffer)
    var entries: [KeyBundleEntry] = []
    var seenPaths = Set<String>()
    entries.reserveCapacity(directoryEnd.entryCount)
    var offset = directoryEnd.centralDirectoryOffset
    for _ in 0..<directoryEnd.entryCount {
      let record = try ZipCentralDirectoryRecord.parse(from: buffer, at: offset)
      entries.append(try entry(for: record, in: buffer))
      guard seenPaths.insert(record.path).inserted else {
        throw KeyBundleError.duplicateEntryPath(record.path)
      }
      offset += record.recordByteCount
    }
    return entries
  }

  /// Serializes `entries` as a `STORED`-only zip, preserving order verbatim.
  internal func serialize(_ entries: [KeyBundleEntry]) throws -> [UInt8] {
    try validate(entries)
    var output = ZipBytes()
    let (offsets, checksums) = try appendLocalEntries(entries, to: &output)
    let directoryOffset = output.bytes.count
    guard directoryOffset < 0xFFFF_FFFF else {
      throw KeyBundleError.zip64Unsupported
    }
    for (index, entry) in entries.enumerated() {
      ZipCentralDirectoryRecord.append(
        to: &output,
        entry: entry,
        crc: checksums[index],
        localHeaderOffset: offsets[index]
      )
    }
    guard output.bytes.count - directoryOffset < 0xFFFF_FFFF else {
      throw KeyBundleError.zip64Unsupported
    }
    ZipEndOfCentralDirectory.append(
      to: &output,
      entryCount: entries.count,
      centralDirectoryOffset: directoryOffset,
      centralDirectoryByteCount: output.bytes.count - directoryOffset
    )
    return output.bytes
  }

  /// Rejects duplicate paths and anything needing zip64 before writing.
  private func validate(_ entries: [KeyBundleEntry]) throws {
    var seenPaths = Set<String>()
    for entry in entries {
      guard seenPaths.insert(entry.path).inserted else {
        throw KeyBundleError.duplicateEntryPath(entry.path)
      }
      guard entry.body.count < 0xFFFF_FFFF else {
        throw KeyBundleError.zip64Unsupported
      }
    }
    guard entries.count < 0xFFFF else {
      throw KeyBundleError.zip64Unsupported
    }
  }

  /// Appends each entry's local header and body, returning header offsets
  /// and checksums for the central directory.
  private func appendLocalEntries(
    _ entries: [KeyBundleEntry],
    to output: inout ZipBytes
  ) throws -> (offsets: [Int], checksums: [UInt32]) {
    var offsets: [Int] = []
    var checksums: [UInt32] = []
    for entry in entries {
      // Individually sub-4 GiB bodies can still push later header offsets
      // past the 32-bit fields; guard the cumulative offset so oversized
      // archives throw instead of trapping in the UInt32 appends.
      guard output.bytes.count < 0xFFFF_FFFF else {
        throw KeyBundleError.zip64Unsupported
      }
      offsets.append(output.bytes.count)
      let crc = CRC32.checksum(entry.body[...])
      checksums.append(crc)
      ZipLocalFileHeader.append(to: &output, entry: entry, crc: crc)
      output.append(contentsOf: entry.body)
    }
    return (offsets, checksums)
  }

  /// Extracts and verifies one entry's body via its central directory record.
  private func entry(
    for record: ZipCentralDirectoryRecord,
    in buffer: ZipBytes
  ) throws -> KeyBundleEntry {
    guard record.method == 0 else {
      throw KeyBundleError.unsupportedCompressionMethod(record.method, path: record.path)
    }
    guard record.compressedByteCount == record.uncompressedByteCount else {
      throw KeyBundleError.truncatedArchive(context: "STORED size mismatch at \(record.path)")
    }
    let header = try ZipLocalFileHeader.parse(from: buffer, at: record.localHeaderOffset)
    let bodyStart = header.bodyOffset(fromHeaderAt: record.localHeaderOffset)
    let bodyEnd = bodyStart + record.compressedByteCount
    guard bodyEnd <= buffer.bytes.count else {
      throw KeyBundleError.truncatedArchive(context: "entry body at \(record.path)")
    }
    let body = buffer.bytes[bodyStart..<bodyEnd]
    guard CRC32.checksum(body) == record.crc else {
      throw KeyBundleError.checksumMismatch(path: record.path)
    }
    return KeyBundleEntry(path: record.path, body: Array(body))
  }
}
