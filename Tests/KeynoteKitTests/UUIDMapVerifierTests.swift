import Foundation
import KeynoteKit
import KeynoteKitProtobuf
import Testing

/// The SIGTRAP invariants must fail loudly, not just pass silently: a
/// verifier that cannot fail would repeat the 4-deck bisect.
@Suite("UUID map verifier")
internal struct UUIDMapVerifierTests {
  @Test("accepts a registered build with matching uuid")
  internal func acceptsRegisteredBuild() throws {
    let members = try makeMembers(registered: true, lastObjectIdentifier: 101)
    try UUIDMapVerifier.verify(members: members, expectedBuildCount: 1)
  }

  @Test("rejects an unregistered build archive")
  internal func rejectsUnregisteredBuild() throws {
    let members = try makeMembers(registered: false, lastObjectIdentifier: 101)
    #expect(throws: ArchiveSurgeryError.self) {
      try UUIDMapVerifier.verify(members: members, expectedBuildCount: 1)
    }
  }

  @Test("rejects a lastObjectIdentifier below the minted ids")
  internal func rejectsLowWaterMark() throws {
    let members = try makeMembers(registered: true, lastObjectIdentifier: 99)
    #expect(throws: ArchiveSurgeryError.self) {
      try UUIDMapVerifier.verify(members: members, expectedBuildCount: 1)
    }
  }

  @Test("rejects a registered uuid that mismatches the chunk buildId")
  internal func rejectsMismatchedUUID() throws {
    var members = try makeMembers(registered: true, lastObjectIdentifier: 101)
    var metadata = try TSP_PackageMetadata(
      serializedBytes: members[1].records[0].payloads[0],
      partial: true
    )
    metadata.components[0].objectUuidMapEntries[0].uuid.lower ^= 1
    members[1].records[0].payloads[0] = try metadata.serializedBytes(partial: true)
    #expect(throws: ArchiveSurgeryError.self) {
      try UUIDMapVerifier.verify(members: members, expectedBuildCount: 1)
    }
  }

  /// A minimal document: one minted build pair + package metadata.
  private func makeMembers(
    registered: Bool,
    lastObjectIdentifier: UInt64
  ) throws -> [KeynoteArchiveSurgeon.Member] {
    var generator = SystemRandomNumberGenerator()
    let build = AuthoredBuild(
      kind: .buildIn,
      effect: "apple:dissolve character",
      targetIndex: 0
    )
    let mint = try BuildRecordFactory.mint(
      build,
      drawableIdentifier: 50,
      buildIdentifier: 100,
      chunkIdentifier: 101,
      using: &generator
    )

    var component = TSP_ComponentInfo()
    component.identifier = 10
    if registered {
      var entry = TSP_ObjectUUIDMapEntry()
      entry.identifier = 100
      entry.uuid = mint.buildUUID
      component.objectUuidMapEntries = [entry]
    }
    var metadata = TSP_PackageMetadata()
    metadata.components = [component]
    metadata.lastObjectIdentifier = lastObjectIdentifier
    var metadataInfo = TSP_ArchiveInfo()
    metadataInfo.identifier = 2
    var metadataMessage = TSP_MessageInfo()
    metadataMessage.type = 11_006
    metadataMessage.version = BuildRecordFactory.version
    metadataInfo.messageInfos = [metadataMessage]
    let metadataRecord = TSPArchiveRecord(
      info: metadataInfo,
      payloads: [try metadata.serializedBytes(partial: true)]
    )

    return [
      (path: "Index/Slide-10.iwa", records: [mint.buildRecord, mint.chunkRecord]),
      (path: "Index/Metadata.iwa", records: [metadataRecord]),
    ]
  }
}
