import Foundation
import KeynoteKit
import KeynoteKitProtobuf
import Testing

/// The cloner's rewrite inventory must cover every slide list the surgeon
/// writes, and must never materialize absent optional message fields.
@Suite("Record cloner")
internal struct RecordClonerTests {
  @Test("remaps ownedDrawables alongside drawablesZOrder")
  internal func remapsOwnedDrawables() throws {
    var slide = KN_SlideArchive()
    var reference = TSP_Reference()
    reference.identifier = 50
    slide.drawablesZOrder = [reference]
    slide.ownedDrawables = [reference]
    let cloned = try RecordCloner.clone(
      [slideRecord(slide, identifier: 1)],
      map: [1: 101, 50: 150]
    )
    let out = try KN_SlideArchive(serializedBytes: cloned[0].payloads[0], partial: true)
    #expect(out.drawablesZOrder.map(\.identifier) == [150])
    #expect(out.ownedDrawables.map(\.identifier) == [150])
  }

  @Test("leaves an absent storage attachment table absent")
  internal func absentTableAttachmentStaysAbsent() throws {
    let typeIdentifier = try #require(
      TSPRegistryMapping.identifiers.first {
        TSPRegistryMapping.messageName(for: $0) == "TSWP.StorageArchive"
      }
    )
    var messageInfo = TSP_MessageInfo()
    messageInfo.type = typeIdentifier
    messageInfo.version = BuildRecordFactory.version
    var info = TSP_ArchiveInfo()
    info.identifier = 7
    info.messageInfos = [messageInfo]
    let record = TSPArchiveRecord(
      info: info,
      payloads: [try TSWP_StorageArchive().serializedBytes(partial: true)]
    )
    let cloned = try RecordCloner.clone([record], map: [7: 107])
    let out = try TSWP_StorageArchive(serializedBytes: cloned[0].payloads[0], partial: true)
    #expect(!out.hasTableAttachment)
  }

  /// Wraps `slide` in a record tagged with the `KN.SlideArchive` type.
  private func slideRecord(_ slide: KN_SlideArchive, identifier: UInt64) -> TSPArchiveRecord {
    var messageInfo = TSP_MessageInfo()
    messageInfo.type = 5
    messageInfo.version = BuildRecordFactory.version
    var info = TSP_ArchiveInfo()
    info.identifier = identifier
    info.messageInfos = [messageInfo]
    return TSPArchiveRecord(
      info: info,
      payloads: [(try? slide.serializedBytes(partial: true)) ?? []]
    )
  }
}
