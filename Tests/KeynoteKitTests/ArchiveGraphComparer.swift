import Foundation
import IWAFraming
import KeynoteKitProtobuf
import SwiftProtobuf

/// Archive-graph equality between a Swift-authored bundle and a golden,
/// normalizing exactly the two per-emit random fields
/// (`animationAttributes.randomNumberSeed` and the 128-bit build uuid) —
/// nothing else is masked.
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
      authored.info.messageInfos.map(\.objectReferences)
        == golden.info.messageInfos.map(\.objectReferences),
      authored.info.messageInfos.map(\.dataReferences)
        == golden.info.messageInfos.map(\.dataReferences)
    else {
      return "record \(identifier): header differs"
    }
    let authoredMessages = try authored.decodedMessages()
    let goldenMessages = try golden.decodedMessages()
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
    default:
      message
    }
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
