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
    var maximumRecordIdentifier: UInt64 = 0
    var slideMemberRecords: [(path: String, identifier: UInt64)] = []
  }

  /// Record types that legitimately live in a slide member without an
  /// `objectUuidMapEntries` row: chunks (only the build id carries the uuid,
  /// paired with the chunk's `buildId`) and number attachments (the bundled
  /// template leaves its own unregistered, so clones stay unregistered too).
  private static let registrationExemptTypes: Set<String> = [
    "KN.BuildChunkArchive",
    "TSWP.NumberAttachmentArchive",
  ]

  /// Verifies the invariants over parsed members.
  ///
  /// 1. The document holds exactly `expectedBuildCount` build archives.
  /// 2. Every `KN.BuildArchive` id is registered in some component's
  ///    `objectUuidMapEntries`.
  /// 3. Every build has a `KN.BuildChunkArchive` pointing back at it.
  /// 4. The registered uuid equals that chunk's `buildId` exactly.
  /// 5. `lastObjectIdentifier` is at or above every record id.
  /// 6. Every record minted into a presentation slide's member (identifier
  ///    at or above `mintedFrom`) is registered in some component's
  ///    `objectUuidMapEntries` — an unregistered record loads the component
  ///    blank or crashes with an NSSet-nil exception. Types in
  ///    ``registrationExemptTypes`` are exempt.
  /// 7. No `TSWP.StorageArchive` object-attribute entry carries a
  ///    present-but-empty reference (`hasObject` with identifier 0). Keynote
  ///    resolves such a reference to nil and crashes on open. An entry that
  ///    means "same style as the preceding one" must omit `object` entirely
  ///    rather than zero it — the distinction is invisible when reading the
  ///    identifier back, since absent and zeroed both read as 0.
  ///
  /// - Throws: ``ArchiveSurgeryError/invariantViolation(_:)``.
  package static func verify(
    members: [KeynoteArchiveSurgeon.Member],
    expectedBuildCount: Int,
    mintedFrom firstMintedIdentifier: UInt64 = 0
  ) throws {
    let slideMemberIndices = Set(
      ((try? SlideCatalog(members: members).orderedSlides()) ?? []).map(\.memberIndex)
    )
    let scan = try scanned(
      members: members,
      slideMemberIndices: slideMemberIndices,
      firstMintedIdentifier: firstMintedIdentifier
    )
    guard scan.buildIdentifiers.count == expectedBuildCount else {
      throw ArchiveSurgeryError.invariantViolation(
        "expected \(expectedBuildCount) build archives, found \(scan.buildIdentifiers.count)"
      )
    }
    for buildIdentifier in scan.buildIdentifiers {
      try checkRegistration(of: buildIdentifier, in: scan)
    }
    if let last = scan.lastObjectIdentifier, last < scan.maximumRecordIdentifier {
      throw ArchiveSurgeryError.invariantViolation(
        "lastObjectIdentifier \(last) is below the highest record id "
          + "\(scan.maximumRecordIdentifier)"
      )
    }
    for record in scan.slideMemberRecords where scan.registered[record.identifier] == nil {
      throw ArchiveSurgeryError.invariantViolation(
        "minted record \(record.identifier) in slide member \(record.path) has no "
          + "objectUuidMapEntries row (Keynote loads the slide blank or crashes)"
      )
    }
    try checkStorageReferences(members: members)
  }

  /// Rule 7: no storage object-attribute entry may carry a present-but-empty
  /// reference.
  ///
  /// `entry.object.identifier = 0` materializes an empty `TSP.Reference`
  /// that Keynote resolves to nil and crashes on, while omitting `object`
  /// correctly means "inherit the preceding entry's style". Both read back
  /// as identifier 0, so only `hasObject` distinguishes them — which is why
  /// this needs a dedicated check rather than an identifier comparison.
  private static func checkStorageReferences(
    members: [KeynoteArchiveSurgeon.Member]
  ) throws {
    for member in members {
      for record in member.records {
        for (index, type) in record.resolvedTypes.enumerated()
        where TSPRegistryMapping.messageName(for: type) == "TSWP.StorageArchive" {
          let storage = try TSWP_StorageArchive(
            serializedBytes: record.payloads[index],
            partial: true
          )
          let tables = [storage.tableParaStyle, storage.tableCharStyle, storage.tableListStyle]
          for table in tables {
            for entry in table.entries where entry.hasObject && entry.object.identifier == 0 {
              throw ArchiveSurgeryError.invariantViolation(
                "storage \(record.info.identifier) has an object-attribute entry at "
                  + "character \(entry.characterIndex) with a present-but-empty reference "
                  + "(Keynote resolves it to nil and crashes on open)"
              )
            }
          }
        }
      }
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

  private static func scanned(
    members: [KeynoteArchiveSurgeon.Member],
    slideMemberIndices: Set<Int>,
    firstMintedIdentifier: UInt64
  ) throws -> Scan {
    var scan = Scan()
    for (memberIndex, member) in members.enumerated() {
      for record in member.records {
        scan.maximumRecordIdentifier = max(
          scan.maximumRecordIdentifier,
          record.info.identifier
        )
        if slideMemberIndices.contains(memberIndex),
          record.info.identifier >= firstMintedIdentifier,
          !record.resolvedTypes.contains(where: {
            registrationExemptTypes.contains(TSPRegistryMapping.messageName(for: $0) ?? "")
          })
        {
          scan.slideMemberRecords.append((path: member.path, record.info.identifier))
        }
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
