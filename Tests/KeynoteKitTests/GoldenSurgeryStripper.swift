import Foundation
import IWAFraming
import KeynoteKitProtobuf

/// Reverses the archive surgery inside a golden, recovering the AppleScript
/// base the Python backend authored onto. Re-applying the same spec with the
/// Swift surgeon must then reproduce the golden's archive graph (the ids
/// match because both writers allocate from the same high-water scan).
internal enum GoldenSurgeryStripper {
  /// Returns `bundle` with all builds, build chunks, their references,
  /// uuid-map entries, node flags, and transition directions removed.
  internal static func stripped(_ bundle: KeyBundle) throws -> KeyBundle {
    var stripped = bundle
    var removed = Set<UInt64>()
    var buildIdentifiers = Set<UInt64>()
    var strippedSlideIdentifiers = Set<UInt64>()

    for path in bundle.indexEntryPaths {
      guard let entry = bundle.entry(at: path) else { continue }
      var records = try TSPArchiveStream.default.records(
        from: IWAChunkCodec.default.decode(entry.body)
      )
      records.removeAll { record in
        let names = record.resolvedTypes.compactMap(TSPRegistryMapping.messageName(for:))
        guard names.contains("KN.BuildArchive") || names.contains("KN.BuildChunkArchive") else {
          return false
        }
        removed.insert(record.info.identifier)
        if names.contains("KN.BuildArchive") {
          buildIdentifiers.insert(record.info.identifier)
        }
        return true
      }
      for index in records.indices {
        try stripSlide(
          record: &records[index],
          removed: removed,
          strippedSlides: &strippedSlideIdentifiers
        )
      }
      stripped.setBody(
        IWAChunkCodec.default.encode(try TSPArchiveStream.default.serialize(records)),
        at: path
      )
    }
    try stripNodesAndMetadata(
      in: &stripped,
      buildIdentifiers: buildIdentifiers,
      strippedSlides: strippedSlideIdentifiers
    )
    return stripped
  }

  /// Clears builds, chunks, references, and transition direction on a slide.
  private static func stripSlide(
    record: inout TSPArchiveRecord,
    removed: Set<UInt64>,
    strippedSlides: inout Set<UInt64>
  ) throws {
    guard
      let payloadIndex = record.resolvedTypes.firstIndex(where: {
        TSPRegistryMapping.messageName(for: $0) == "KN.SlideArchive"
      })
    else {
      return
    }
    var slide = try KN_SlideArchive(serializedBytes: record.payloads[payloadIndex], partial: true)
    if !slide.builds.isEmpty {
      strippedSlides.insert(record.info.identifier)
    }
    slide.builds.removeAll { removed.contains($0.identifier) }
    slide.buildChunks.removeAll { removed.contains($0.identifier) }
    if slide.hasTransition, slide.transition.hasAttributes,
      slide.transition.attributes.hasAnimationAttributes
    {
      slide.transition.attributes.animationAttributes.clearDirection()
    }
    record.payloads[payloadIndex] = try slide.serializedBytes(partial: true)
    for index in record.info.messageInfos.indices {
      record.info.messageInfos[index].objectReferences.removeAll { removed.contains($0) }
    }
  }

  /// Clears node build flags for stripped slides and unregisters uuid
  /// entries; drops `lastObjectIdentifier` to 1 so re-authoring re-mints
  /// the same ids the Python writer did.
  private static func stripNodesAndMetadata(
    in bundle: inout KeyBundle,
    buildIdentifiers: Set<UInt64>,
    strippedSlides: Set<UInt64>
  ) throws {
    guard !buildIdentifiers.isEmpty else {
      return
    }
    for path in bundle.indexEntryPaths {
      guard let entry = bundle.entry(at: path) else { continue }
      var records = try TSPArchiveStream.default.records(
        from: IWAChunkCodec.default.decode(entry.body)
      )
      let dirty = try stripMember(
        records: &records,
        buildIdentifiers: buildIdentifiers,
        strippedSlides: strippedSlides
      )
      if dirty {
        bundle.setBody(
          IWAChunkCodec.default.encode(try TSPArchiveStream.default.serialize(records)),
          at: path
        )
      }
    }
  }

  /// Strips every node/metadata payload in one member; true when changed.
  private static func stripMember(
    records: inout [TSPArchiveRecord],
    buildIdentifiers: Set<UInt64>,
    strippedSlides: Set<UInt64>
  ) throws -> Bool {
    var dirty = false
    for recordIndex in records.indices {
      for (payloadIndex, type) in records[recordIndex].resolvedTypes.enumerated() {
        let stripped = try strippedPayload(
          records[recordIndex].payloads[payloadIndex],
          type: type,
          buildIdentifiers: buildIdentifiers,
          strippedSlides: strippedSlides
        )
        if let stripped {
          records[recordIndex].payloads[payloadIndex] = stripped
          dirty = true
        }
      }
    }
    return dirty
  }

  /// The replacement payload for a node or metadata message, or `nil`.
  private static func strippedPayload(
    _ payload: [UInt8],
    type: UInt32,
    buildIdentifiers: Set<UInt64>,
    strippedSlides: Set<UInt64>
  ) throws -> [UInt8]? {
    switch TSPRegistryMapping.messageName(for: type) {
    case "KN.SlideNodeArchive":
      try strippedNode(payload, strippedSlides: strippedSlides)
    case "TSP.PackageMetadata":
      try strippedMetadata(payload, buildIdentifiers: buildIdentifiers)
    default:
      nil
    }
  }

  /// Clears the build flags on a stripped slide's node, or returns `nil`
  /// when the node belongs to an untouched slide.
  private static func strippedNode(
    _ payload: [UInt8],
    strippedSlides: Set<UInt64>
  ) throws -> [UInt8]? {
    var node = try KN_SlideNodeArchive(serializedBytes: payload, partial: true)
    guard node.hasSlide, strippedSlides.contains(node.slide.identifier) else {
      return nil
    }
    node.clearBuildEventCount()
    node.clearBuildEventCountCacheVersion()
    node.clearHasExplicitBuilds_p()
    node.clearHasExplicitBuildsCacheVersion_p()
    return try node.serializedBytes(partial: true)
  }

  /// Unregisters the removed builds and drops the id high-water mark.
  private static func strippedMetadata(
    _ payload: [UInt8],
    buildIdentifiers: Set<UInt64>
  ) throws -> [UInt8]? {
    var metadata = try TSP_PackageMetadata(serializedBytes: payload, partial: true)
    for componentIndex in metadata.components.indices {
      metadata.components[componentIndex].objectUuidMapEntries.removeAll {
        buildIdentifiers.contains($0.identifier)
      }
    }
    metadata.lastObjectIdentifier = 1
    return try metadata.serializedBytes(partial: true)
  }
}
