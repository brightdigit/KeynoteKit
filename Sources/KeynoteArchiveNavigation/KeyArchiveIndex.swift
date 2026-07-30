//
//  KeyArchiveIndex.swift
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

package import IWAFraming
package import KeynoteKitProtobuf

/// Every `Index/*.iwa` member of a bundle, de-framed and split into records.
///
/// This is #18's navigation surface: enough to locate slides, builds, and
/// drawable targets in fixtures at archive level. It is deliberately
/// `package`-scoped — reading a `.key` is test infrastructure and writer
/// plumbing, not public API (#6).
package struct KeyArchiveIndex {
  /// `Index/*.iwa` paths, in archive order.
  package let entryPaths: [String]

  private let recordsByPath: [String: [TSPArchiveRecord]]

  /// De-frames and parses every `Index/*.iwa` member of `bundle`.
  ///
  /// - Parameter bundle: A parsed `.key` bundle.
  /// - Throws: Framing or delimiting errors from the underlying layers.
  package init(bundle: KeyBundle) throws {
    let paths = bundle.indexEntryPaths
    var recordsByPath: [String: [TSPArchiveRecord]] = [:]
    for path in paths {
      guard let entry = bundle.entry(at: path) else { continue }
      let stream = try IWAChunkCodec.decode(entry.body)
      recordsByPath[path] = try TSPArchiveStream.records(from: stream)
    }
    self.entryPaths = paths
    self.recordsByPath = recordsByPath
  }

  /// The records of the member at `path`, in stream order.
  package func records(at path: String) -> [TSPArchiveRecord]? {
    recordsByPath[path]
  }

  /// The first record whose `ArchiveInfo.identifier` matches, with the path
  /// of the member holding it, searching members in archive order.
  package func record(withIdentifier identifier: UInt64) -> (
    path: String, record: TSPArchiveRecord
  )? {
    for path in entryPaths {
      guard let records = recordsByPath[path] else { continue }
      if let record = records.first(where: { $0.info.identifier == identifier }) {
        return (path: path, record: record)
      }
    }
    return nil
  }
}
