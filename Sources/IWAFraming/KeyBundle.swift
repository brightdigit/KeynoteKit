//
//  KeyBundle.swift
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

/// A `.key` document as an ordered list of named byte entries.
///
/// This is deliberately a dumb container: entries stay verbatim bytes in
/// archive order, and `.iwa` members are decoded on demand by callers via
/// ``IWAChunkCodec``. That shape is what archive surgery wants — mutate one
/// entry, leave the other twenty-plus byte-identical.
///
/// Every committed Keynote document stores all entries uncompressed
/// (`STORED`, 1,604 of 1,604 measured entries), so both the reader and
/// ``serializedZip()`` speak only that subset of the zip format.
public struct KeyBundle: Equatable, Sendable {
  /// The bundle's entries, in archive order; order is preserved on write.
  public var entries: [KeyBundleEntry]

  /// Paths of the `Index/*.iwa` members, in archive order.
  public var indexEntryPaths: [String] {
    entries.map(\.path)
      .filter { $0.hasPrefix("Index/") && $0.hasSuffix(".iwa") }
  }

  /// Creates a bundle from entries already in hand.
  ///
  /// - Parameter entries: The entries, in the order they should be written.
  public init(entries: [KeyBundleEntry]) {
    self.entries = entries
  }

  /// Parses a `.key` zip archive.
  ///
  /// - Parameter bytes: The full archive contents.
  /// - Throws: ``KeyBundleError`` if the input is not a single-disk,
  ///   `STORED`-only zip with intact checksums.
  public init(contentsOfZip bytes: [UInt8]) throws {
    self.entries = try ZipArchive.default.entries(from: bytes)
  }

  /// Serializes the bundle as a `STORED`-only zip archive.
  ///
  /// - Returns: Bytes suitable for writing as a `.key` file.
  /// - Throws: ``KeyBundleError`` for duplicate paths or zip64-scale content.
  public func serializedZip() throws -> [UInt8] {
    try ZipArchive.default.serialize(entries)
  }

  /// The entry at `path`, if present.
  ///
  /// - Parameter path: The entry path to look up.
  /// - Returns: The entry, or `nil` when no entry has that path.
  public func entry(at path: String) -> KeyBundleEntry? {
    entries.first { $0.path == path }
  }

  /// Replaces the body of the entry at `path`, leaving its position intact.
  ///
  /// Does nothing when no entry has that path.
  ///
  /// - Parameters:
  ///   - body: The new bytes for the entry.
  ///   - path: The path of the entry to replace.
  public mutating func setBody(_ body: [UInt8], at path: String) {
    guard let index = entries.firstIndex(where: { $0.path == path }) else {
      return
    }
    entries[index].body = body
  }

  /// Inserts or replaces an entry at `path`, preserving archive order.
  ///
  /// New `Data/` members are inserted after existing `Data/` entries (and
  /// before `Index/`), matching Keynote's usual zip layout.
  ///
  /// - Parameters:
  ///   - body: The uncompressed entry bytes.
  ///   - path: The entry path within the bundle.
  public mutating func upsertEntry(body: [UInt8], at path: String) {
    if let index = entries.firstIndex(where: { $0.path == path }) {
      entries[index].body = body
      return
    }
    let entry = KeyBundleEntry(path: path, body: body)
    if path.hasPrefix("Data/") {
      if let lastData = entries.lastIndex(where: { $0.path.hasPrefix("Data/") }) {
        entries.insert(entry, at: lastData + 1)
      } else if let firstIndex = entries.firstIndex(where: { $0.path.hasPrefix("Index/") }) {
        entries.insert(entry, at: firstIndex)
      } else {
        entries.insert(entry, at: 0)
      }
    } else {
      entries.append(entry)
    }
  }
}
