//
//  KeynoteArchiveSurgeon+DataIdentifiers.swift
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

import Foundation
package import KeynoteKitProtobuf

extension KeynoteArchiveSurgeon {
  /// Next unused `TSP.DataInfo.identifier`.
  internal func nextDataIdentifier() throws -> UInt64 {
    let catalog = SlideCatalog(members: members)
    guard let location = try catalog.locateFirst(named: "TSP.PackageMetadata") else {
      throw ArchiveSurgeryError.missingSlideComponent(slideIdentifier: 0)
    }
    let metadata = try TSP_PackageMetadata(
      serializedBytes: members[location.memberIndex]
        .records[location.recordIndex]
        .payloads[location.payloadIndex],
      partial: true
    )
    let maximum = metadata.datas.map(\.identifier).max() ?? 0
    return maximum + 1
  }

  /// The first `TSD.MediaStyleArchive` in the document stylesheet, if any.
  internal func mediaStyleIdentifier() throws -> UInt64? {
    for member in members {
      for record in member.records {
        let names = record.resolvedTypes.compactMap { TSPRegistryMapping.messageName(for: $0) }
        if names.contains("TSD.MediaStyleArchive") {
          return record.info.identifier
        }
      }
    }
    return nil
  }

  /// Formats a lowercase UUID string from `generator`.
  internal func uuidString(using generator: inout some RandomNumberGenerator) -> String {
    var bytes: [UInt8] = []
    bytes.reserveCapacity(16)
    for _ in 0..<16 {
      bytes.append(UInt8.random(in: .min ... .max, using: &generator))
    }
    bytes[6] = (bytes[6] & 0x0F) | 0x40
    bytes[8] = (bytes[8] & 0x3F) | 0x80
    let uuid = UUID(
      uuid: (
        bytes[0], bytes[1], bytes[2], bytes[3],
        bytes[4], bytes[5], bytes[6], bytes[7],
        bytes[8], bytes[9], bytes[10], bytes[11],
        bytes[12], bytes[13], bytes[14], bytes[15]
      )
    )
    return uuid.uuidString
  }
}
