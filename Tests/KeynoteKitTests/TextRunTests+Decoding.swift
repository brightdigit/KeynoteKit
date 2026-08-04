import Foundation
import KeynoteKit
import KeynoteKitProtobuf
import Testing

extension TextRunTests {
  /// Decodes the first slide's `KN.SlideArchive`.
  internal func firstSlideArchive(in surgeon: KeynoteArchiveSurgeon) throws -> KN_SlideArchive {
    let catalog = SlideCatalog(members: surgeon.members)
    let slide = try #require(try catalog.orderedSlides().first)
    return try KN_SlideArchive(
      serializedBytes: surgeon.members[slide.memberIndex].records[slide.recordIndex].payloads[0],
      partial: true
    )
  }

  internal func placeholder(
    forDrawable identifier: UInt64,
    in surgeon: KeynoteArchiveSurgeon
  ) throws -> KN_PlaceholderArchive {
    let catalog = SlideCatalog(members: surgeon.members)
    let location = try #require(
      try catalog.locate(recordIdentifier: identifier, named: "KN.PlaceholderArchive")
    )
    return try KN_PlaceholderArchive(
      serializedBytes: surgeon.members[location.memberIndex]
        .records[location.recordIndex]
        .payloads[location.payloadIndex],
      partial: true
    )
  }

  internal func storage(
    forDrawable identifier: UInt64,
    in surgeon: KeynoteArchiveSurgeon
  ) throws -> TSWP_StorageArchive {
    let catalog = SlideCatalog(members: surgeon.members)
    let shape = try placeholder(forDrawable: identifier, in: surgeon)
    let location = try #require(
      try catalog.locate(
        recordIdentifier: shape.super.ownedStorage.identifier,
        named: "TSWP.StorageArchive"
      )
    )
    return try TSWP_StorageArchive(
      serializedBytes: surgeon.members[location.memberIndex]
        .records[location.recordIndex]
        .payloads[location.payloadIndex],
      partial: true
    )
  }

  internal func characterStyle(
    _ identifier: UInt64,
    in surgeon: KeynoteArchiveSurgeon
  ) throws -> TSWP_CharacterStyleArchive {
    let catalog = SlideCatalog(members: surgeon.members)
    let location = try #require(
      try catalog.locate(recordIdentifier: identifier, named: "TSWP.CharacterStyleArchive")
    )
    return try TSWP_CharacterStyleArchive(
      serializedBytes: surgeon.members[location.memberIndex]
        .records[location.recordIndex]
        .payloads[location.payloadIndex],
      partial: true
    )
  }

  internal func paragraphStyle(
    _ identifier: UInt64,
    in surgeon: KeynoteArchiveSurgeon
  ) throws -> TSWP_ParagraphStyleArchive {
    let catalog = SlideCatalog(members: surgeon.members)
    let location = try #require(
      try catalog.locate(recordIdentifier: identifier, named: "TSWP.ParagraphStyleArchive")
    )
    return try TSWP_ParagraphStyleArchive(
      serializedBytes: surgeon.members[location.memberIndex]
        .records[location.recordIndex]
        .payloads[location.payloadIndex],
      partial: true
    )
  }
}
