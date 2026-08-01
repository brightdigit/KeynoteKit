import Foundation
import IWAFraming
import KeynoteKitProtobuf
import SwiftProtobuf

/// Archive-graph equality between a Swift-authored bundle and a golden,
/// normalizing exactly the two per-emit random fields
/// (`animationAttributes.randomNumberSeed` and the 128-bit build uuid) plus
/// one authored divergence: each `TSWP.StorageArchive`'s `tableListStyle` is
/// cleared and its referenced ids dropped from that record's header
/// references on both sides — Swift repoints bare text boxes at the theme's
/// None list style (plain by default, issue #51) while the Python goldens
/// keep the template's bullet reference. Nothing else is masked.
internal enum ArchiveGraphComparer {
  /// A human-readable description of the first difference, or `nil` when
  /// the graphs match.
  internal static func firstDifference(
    between authored: KeyBundle,
    and golden: KeyBundle
  ) throws -> String? {
    guard authored.indexEntryPaths == golden.indexEntryPaths else {
      return "index member lists differ"
    }
    for path in golden.indexEntryPaths {
      guard let authoredEntry = authored.entry(at: path), let goldenEntry = golden.entry(at: path)
      else {
        return "\(path): missing member"
      }
      let authoredRecords = try TSPArchiveStream.default.records(
        from: IWAChunkCodec.default.decode(authoredEntry.body)
      )
      let goldenRecords = try TSPArchiveStream.default.records(
        from: IWAChunkCodec.default.decode(goldenEntry.body)
      )
      guard authoredRecords.count == goldenRecords.count else {
        return "\(path): record count \(authoredRecords.count) != \(goldenRecords.count)"
      }
      for (authoredRecord, goldenRecord) in zip(authoredRecords, goldenRecords) {
        if let difference = try recordDifference(authoredRecord, goldenRecord) {
          return "\(path): \(difference)"
        }
      }
    }
    return nil
  }

  /// Compares one record pair: header fields, then decoded messages with
  /// the volatile fields cleared.
  private static func recordDifference(
    _ authored: TSPArchiveRecord,
    _ golden: TSPArchiveRecord
  ) throws -> String? {
    guard authored.info.identifier == golden.info.identifier else {
      return "record \(golden.info.identifier): identifier \(authored.info.identifier)"
    }
    let identifier = golden.info.identifier
    guard authored.resolvedTypes == golden.resolvedTypes,
      authored.info.messageInfos.map(\.version) == golden.info.messageInfos.map(\.version),
      authored.info.messageInfos.map(\.dataReferences)
        == golden.info.messageInfos.map(\.dataReferences)
    else {
      return "record \(identifier): header differs"
    }
    let authoredMessages = try authored.decodedMessages()
    let goldenMessages = try golden.decodedMessages()
    guard
      normalizedObjectReferences(of: authored, messages: authoredMessages)
        == normalizedObjectReferences(of: golden, messages: goldenMessages)
    else {
      return "record \(identifier): header differs"
    }
    for (offset, type) in authored.resolvedTypes.enumerated() {
      let name = TSPRegistryMapping.messageName(for: type) ?? "?"
      let same = isEqual(
        normalized(authoredMessages[offset], name: name),
        normalized(goldenMessages[offset], name: name)
      )
      if !same {
        return "record \(identifier) message \(offset) (\(name)) differs"
      }
    }
    return nil
  }

  /// Clears the per-emit random fields on the message types that carry them.
  private static func normalized(_ message: any Message, name: String) -> any Message {
    switch name {
    case "KN.BuildArchive":
      normalizedBuild(message)
    case "KN.BuildChunkArchive":
      normalizedChunk(message)
    case "TSP.PackageMetadata":
      normalizedMetadata(message)
    case "TSWP.StorageArchive":
      normalizedStorage(message)
    default:
      message
    }
  }

  /// Header object references with the record's own list-style ids removed —
  /// the sole reference the Swift author intentionally repoints away from
  /// the golden (bullet → None).
  private static func normalizedObjectReferences(
    of record: TSPArchiveRecord,
    messages: [any Message]
  ) -> [[UInt64]] {
    let listStyleIdentifiers = Set(
      messages
        .compactMap { $0 as? TSWP_StorageArchive }
        .flatMap { $0.tableListStyle.entries.map(\.object.identifier) }
    )
    guard !listStyleIdentifiers.isEmpty else {
      return record.info.messageInfos.map(\.objectReferences)
    }
    return record.info.messageInfos.map { info in
      info.objectReferences.filter { !listStyleIdentifiers.contains($0) }
    }
  }

  /// Clears the intentionally-repointed list-style table on a text storage.
  private static func normalizedStorage(_ message: any Message) -> any Message {
    guard var storage = message as? TSWP_StorageArchive else {
      return message
    }
    storage.clearTableListStyle()
    return storage
  }

  /// Clears the animation seed on a build.
  private static func normalizedBuild(_ message: any Message) -> any Message {
    guard var build = message as? KN_BuildArchive else {
      return message
    }
    build.attributes.animationAttributes.clearRandomNumberSeed()
    return build
  }

  /// Clears the random 128-bit uuid on a build chunk.
  private static func normalizedChunk(_ message: any Message) -> any Message {
    guard var chunk = message as? KN_BuildChunkArchive else {
      return message
    }
    chunk.clearBuildID()
    chunk.buildChunkIdentifier.clearBuildID()
    return chunk
  }

  /// Clears the registered uuids (their pairing is verified separately).
  private static func normalizedMetadata(_ message: any Message) -> any Message {
    guard var metadata = message as? TSP_PackageMetadata else {
      return message
    }
    for index in metadata.components.indices {
      for entryIndex in metadata.components[index].objectUuidMapEntries.indices {
        metadata.components[index].objectUuidMapEntries[entryIndex].clearUuid()
      }
    }
    return metadata
  }

  /// Type-erased protobuf equality.
  private static func isEqual(_ lhs: any Message, _ rhs: any Message) -> Bool {
    guard type(of: lhs) == type(of: rhs) else {
      return false
    }
    return lhs.isEqualTo(message: rhs)
  }
}
