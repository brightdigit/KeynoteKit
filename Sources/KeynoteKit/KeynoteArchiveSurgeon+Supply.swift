//
//  KeynoteArchiveSurgeon+Supply.swift
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

package import IWAFraming
package import KeynoteKitProtobuf

extension KeynoteArchiveSurgeon {
  /// Grows the deck to `count` slides by cloning the last template slide —
  /// its whole member subtree plus its slide node — minting fresh ids and
  /// registering a new component per clone (#22 supply, clone strategy per
  /// the PLAN decision log).
  internal mutating func expandSlides(
    to count: Int,
    in bundle: inout KeyBundle,
    nextIdentifier: inout UInt64
  ) throws {
    while try SlideCatalog(members: members).orderedSlides().count < count {
      try cloneLastSlide(in: &bundle, nextIdentifier: &nextIdentifier)
    }
  }

  /// Ensures a slide's `drawablesZOrder` holds at least `count` drawables:
  /// the template body placeholder is item 0, clones of it follow.
  internal mutating func expandTextItems(
    to count: Int,
    at location: SlideCatalog.Slide,
    nextIdentifier: inout UInt64
  ) throws {
    var slide = try KN_SlideArchive(
      serializedBytes: members[location.memberIndex].records[location.recordIndex].payloads[0],
      partial: true
    )
    if slide.drawablesZOrder.isEmpty, slide.hasBodyPlaceholder, count > 0 {
      slide.drawablesZOrder.append(slide.bodyPlaceholder)
    }
    while slide.drawablesZOrder.count < count {
      let clonedIdentifier = try cloneBodyPlaceholder(
        of: slide,
        at: location,
        nextIdentifier: &nextIdentifier
      )
      var reference = TSP_Reference()
      reference.identifier = clonedIdentifier
      slide.drawablesZOrder.append(reference)
    }
    members[location.memberIndex].records[location.recordIndex].payloads[0] =
      try slide.serializedBytes(partial: true)
  }

  /// Clones the body-placeholder subtree of `slide`, returning the clone's
  /// placeholder identifier and splicing its records after the originals.
  private mutating func cloneBodyPlaceholder(
    of slide: KN_SlideArchive,
    at location: SlideCatalog.Slide,
    nextIdentifier: inout UInt64
  ) throws -> UInt64 {
    let catalog = SlideCatalog(members: members)
    guard slide.hasBodyPlaceholder,
      let placeholderLocation = catalog.locate(
        recordIdentifier: slide.bodyPlaceholder.identifier
      )
    else {
      throw ArchiveSurgeryError.missingSlideRecord(identifier: slide.bodyPlaceholder.identifier)
    }
    let member = members[placeholderLocation.memberIndex]
    let subtree = subtreeRecords(
      from: member.records[placeholderLocation.recordIndex],
      in: member.records,
      excluding: [location.slideIdentifier]
    )
    var map: [UInt64: UInt64] = [:]
    for record in subtree {
      map[record.info.identifier] = nextIdentifier
      nextIdentifier += 1
    }
    var cloned = try RecordCloner.clone(subtree, map: map)
    // The clone's drawable parent stays the same slide, which `map` does not
    // cover, so nothing rewrites it — exactly what we want.
    members[placeholderLocation.memberIndex].records.append(contentsOf: cloned)
    appendHeaderReferences(
      Array(map.values).sorted(),
      toRecordAt: location
    )
    cloned.removeAll()
    return map[slide.bodyPlaceholder.identifier] ?? 0
  }

  /// The records reachable from `root` through its header references,
  /// restricted to `records`' member (external references drop out) and
  /// never crossing into `excluding` (the owning slide).
  private func subtreeRecords(
    from root: TSPArchiveRecord,
    in records: [TSPArchiveRecord],
    excluding: Set<UInt64>
  ) -> [TSPArchiveRecord] {
    var byIdentifier: [UInt64: TSPArchiveRecord] = [:]
    for record in records {
      byIdentifier[record.info.identifier] = record
    }
    var visited = excluding
    var queue = [root.info.identifier]
    var subtree: [TSPArchiveRecord] = []
    while let identifier = queue.popLast() {
      guard visited.insert(identifier).inserted, let record = byIdentifier[identifier] else {
        continue
      }
      subtree.append(record)
      for messageInfo in record.info.messageInfos {
        queue.append(contentsOf: messageInfo.objectReferences)
      }
    }
    return subtree
  }

  /// Appends `identifiers` to the slide record's first `MessageInfo`.
  private mutating func appendHeaderReferences(
    _ identifiers: [UInt64],
    toRecordAt location: SlideCatalog.Slide
  ) {
    var info = members[location.memberIndex].records[location.recordIndex].info
    info.messageInfos[0].objectReferences.append(contentsOf: identifiers)
    members[location.memberIndex].records[location.recordIndex].info = info
  }

  /// Writes each item's string and position into the slide's drawables,
  /// in `drawablesZOrder` order.
  internal mutating func applyTextItems(
    _ items: [AuthoredSlide.TextItem],
    to slideArchive: inout KN_SlideArchive,
    slideIndex: Int
  ) throws {
    let catalog = SlideCatalog(members: members)
    for (index, item) in items.enumerated() {
      guard slideArchive.drawablesZOrder.indices.contains(index) else {
        throw ArchiveSurgeryError.targetOutOfRange(slideIndex: slideIndex, targetIndex: index)
      }
      let drawableIdentifier = slideArchive.drawablesZOrder[index].identifier
      guard
        let location = try catalog.locate(
          recordIdentifier: drawableIdentifier,
          named: "KN.PlaceholderArchive"
        )
      else {
        throw ArchiveSurgeryError.missingSlideRecord(identifier: drawableIdentifier)
      }
      var placeholder = try KN_PlaceholderArchive(
        serializedBytes: members[location.memberIndex]
          .records[location.recordIndex].payloads[location.payloadIndex],
        partial: true
      )
      placeholder.super.super.super.geometry.position.x = Float(item.x)
      placeholder.super.super.super.geometry.position.y = Float(item.y)
      members[location.memberIndex].records[location.recordIndex]
        .payloads[location.payloadIndex] = try placeholder.serializedBytes(partial: true)
      try applyText(item.text, toStorage: placeholder.super.ownedStorage.identifier)
    }
  }

  /// Writes `text` into a placeholder's owned storage.
  private mutating func applyText(_ text: String, toStorage identifier: UInt64) throws {
    let catalog = SlideCatalog(members: members)
    guard
      let location = try catalog.locate(
        recordIdentifier: identifier,
        named: "TSWP.StorageArchive"
      )
    else {
      throw ArchiveSurgeryError.missingSlideRecord(identifier: identifier)
    }
    var storage = try TSWP_StorageArchive(
      serializedBytes: members[location.memberIndex]
        .records[location.recordIndex].payloads[location.payloadIndex],
      partial: true
    )
    storage.text = [text]
    members[location.memberIndex].records[location.recordIndex]
      .payloads[location.payloadIndex] = try storage.serializedBytes(partial: true)
  }
}
