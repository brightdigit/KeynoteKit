import Foundation
import IWAFraming
import KeynoteArchiveNavigation
import KeynoteKitProtobuf
import SwiftProtobuf
import Testing

/// Builds a minimal in-memory deck — document, show, slide tree, nodes, and
/// one member per slide — so order and error paths can be pinned without a
/// fixture whose tree order happens to match member order.
internal enum SyntheticDeck {
  /// An archive index over a synthetic deck.
  ///
  /// - Parameters:
  ///   - treeNodeIdentifiers: `slideTree.slides` node references, in order.
  ///   - nodes: Node identifier → its slide identifier.
  ///   - slideIdentifiers: Slides that get an `Index/Slide-<id>.iwa` member.
  ///   - childrenOfNode: Node identifier → child node references.
  /// - Returns: A parsed index over the synthetic members.
  /// - Throws: Framing or serialization errors from the container layers.
  internal static func index(
    treeNodeIdentifiers: [UInt64],
    nodes: [UInt64: UInt64],
    slideIdentifiers: [UInt64],
    childrenOfNode: [UInt64: [UInt64]] = [:]
  ) throws -> KeyArchiveIndex {
    var documentRecords: [TSPArchiveRecord] = []
    var document = KN_DocumentArchive()
    document.show.identifier = 2
    documentRecords.append(
      try record(identifier: 1, name: "KN.DocumentArchive", message: document)
    )
    var show = KN_ShowArchive()
    show.slideTree.slides = treeNodeIdentifiers.map(reference)
    documentRecords.append(
      try record(identifier: 2, name: "KN.ShowArchive", message: show)
    )
    for (nodeIdentifier, slideIdentifier) in nodes.sorted(by: { $0.key < $1.key }) {
      var node = KN_SlideNodeArchive()
      node.slide.identifier = slideIdentifier
      node.children = (childrenOfNode[nodeIdentifier] ?? []).map(reference)
      documentRecords.append(
        try record(identifier: nodeIdentifier, name: "KN.SlideNodeArchive", message: node)
      )
    }

    var entries = [KeyBundleEntry(path: "Index/Document.iwa", body: try body(documentRecords))]
    for slideIdentifier in slideIdentifiers {
      let slideRecord = try record(
        identifier: slideIdentifier,
        name: "KN.SlideArchive",
        message: KN_SlideArchive()
      )
      entries.append(
        KeyBundleEntry(
          path: "Index/Slide-\(slideIdentifier).iwa",
          body: try body([slideRecord])
        )
      )
    }
    return try KeyArchiveIndex(bundle: KeyBundle(entries: entries))
  }

  /// Frames records as one `.iwa` member body.
  private static func body(_ records: [TSPArchiveRecord]) throws -> [UInt8] {
    IWAChunkCodec.default.encode(try TSPArchiveStream.default.serialize(records))
  }

  /// A `TSP.Reference` to `identifier`.
  private static func reference(_ identifier: UInt64) -> TSP_Reference {
    var reference = TSP_Reference()
    reference.identifier = identifier
    return reference
  }

  /// Wraps `message` in a record tagged with `name`'s registry identifier.
  private static func record(
    identifier: UInt64,
    name: String,
    message: some SwiftProtobuf.Message
  ) throws -> TSPArchiveRecord {
    let type = try #require(
      TSPRegistryMapping.identifiers.first {
        TSPRegistryMapping.messageName(for: $0) == name
      }
    )
    let payload: [UInt8] = try message.serializedBytes(partial: true)
    var messageInfo = TSP_MessageInfo()
    messageInfo.type = type
    messageInfo.length = UInt32(payload.count)
    var info = TSP_ArchiveInfo()
    info.identifier = identifier
    info.messageInfos = [messageInfo]
    return TSPArchiveRecord(info: info, payloads: [payload])
  }
}
