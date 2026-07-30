//
//  UUIDMapVerifier.swift
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

package import KeynoteKitProtobuf

/// The two document-level invariants whose violation crashes Keynote 15.3
/// with SIGTRAP (`research/findings/write_backend_bisect.md`) — a port of
/// Python `_verify_uuid_map`, run as a precondition of every write, not as
/// an afterthought.
package enum UUIDMapVerifier {
  /// Everything the invariants need, gathered in one pass.
  private struct Scan {
    var registered: [UInt64: TSP_UUID] = [:]
    var buildIdentifiers: [UInt64] = []
    var chunkIdentifiers: [UInt64] = []
    var chunkBuildUUIDs: [UInt64: TSP_UUID] = [:]
    var lastObjectIdentifier: UInt64?
  }

  /// Verifies the invariants over parsed members.
  ///
  /// 1. The document holds exactly `expectedBuildCount` build archives.
  /// 2. Every `KN.BuildArchive` id is registered in some component's
  ///    `objectUuidMapEntries`.
  /// 3. Every build has a `KN.BuildChunkArchive` pointing back at it.
  /// 4. The registered uuid equals that chunk's `buildId` exactly.
  /// 5. `lastObjectIdentifier` is at or above every build/chunk id.
  ///
  /// - Throws: ``ArchiveSurgeryError/invariantViolation(_:)``.
  package static func verify(
    members: [KeynoteArchiveSurgeon.Member],
    expectedBuildCount: Int
  ) throws {
    let scan = try scanned(members: members)
    guard scan.buildIdentifiers.count == expectedBuildCount else {
      throw ArchiveSurgeryError.invariantViolation(
        "expected \(expectedBuildCount) build archives, found \(scan.buildIdentifiers.count)"
      )
    }
    for buildIdentifier in scan.buildIdentifiers {
      try checkRegistration(of: buildIdentifier, in: scan)
    }
    let highest = (scan.buildIdentifiers + scan.chunkIdentifiers).max() ?? 0
    if let last = scan.lastObjectIdentifier, !scan.buildIdentifiers.isEmpty, last < highest {
      throw ArchiveSurgeryError.invariantViolation(
        "lastObjectIdentifier \(last) is below the highest authored archive id \(highest)"
      )
    }
  }

  /// Checks one build's registration and chunk pairing.
  private static func checkRegistration(of buildIdentifier: UInt64, in scan: Scan) throws {
    guard let registered = scan.registered[buildIdentifier] else {
      throw ArchiveSurgeryError.invariantViolation(
        "build archive \(buildIdentifier) is not registered (Keynote will crash)"
      )
    }
    guard let chunkUUID = scan.chunkBuildUUIDs[buildIdentifier] else {
      throw ArchiveSurgeryError.invariantViolation(
        "build archive \(buildIdentifier) has no KN.BuildChunkArchive"
      )
    }
    guard registered == chunkUUID else {
      throw ArchiveSurgeryError.invariantViolation(
        "uuid map entry for build \(buildIdentifier) does not match its chunk buildId"
      )
    }
  }

  private static func scanned(members: [KeynoteArchiveSurgeon.Member]) throws -> Scan {
    var scan = Scan()
    for member in members {
      for record in member.records {
        try collect(record: record, into: &scan)
      }
    }
    return scan
  }

  private static func collect(record: TSPArchiveRecord, into scan: inout Scan) throws {
    for (offset, type) in record.resolvedTypes.enumerated() {
      switch TSPRegistryMapping.messageName(for: type) {
      case "TSP.PackageMetadata":
        try collectMetadata(payload: record.payloads[offset], into: &scan)
      case "KN.BuildArchive":
        scan.buildIdentifiers.append(record.info.identifier)
      case "KN.BuildChunkArchive":
        let chunk = try KN_BuildChunkArchive(
          serializedBytes: record.payloads[offset],
          partial: true
        )
        scan.chunkBuildUUIDs[chunk.build.identifier] = chunk.buildID
        scan.chunkIdentifiers.append(record.info.identifier)
      default:
        break
      }
    }
  }

  private static func collectMetadata(payload: [UInt8], into scan: inout Scan) throws {
    let metadata = try TSP_PackageMetadata(serializedBytes: payload, partial: true)
    for component in metadata.components {
      for entry in component.objectUuidMapEntries {
        scan.registered[entry.identifier] = entry.uuid
      }
    }
    if metadata.hasLastObjectIdentifier {
      scan.lastObjectIdentifier = metadata.lastObjectIdentifier
    }
  }
}
