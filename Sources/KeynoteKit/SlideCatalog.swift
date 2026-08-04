//
//  SlideCatalog.swift
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

/// Locates slides and named records across parsed `Index/` members for the
/// surgeon (mirrors Python `_slide_order` / `_load_index` lookups).
package struct SlideCatalog {
  /// A record location: member, record, and payload offsets.
  package struct Location {
    /// The member's index in the surgeon's member list.
    package var memberIndex: Int

    /// The record's index within the member.
    package var recordIndex: Int

    /// The payload's index within the record.
    package var payloadIndex: Int
  }

  /// One slide in presentation order.
  package struct Slide {
    /// The `KN.SlideNodeArchive` record identifier.
    package var nodeIdentifier: UInt64

    /// The `KN.SlideArchive` record identifier.
    package var slideIdentifier: UInt64

    /// The member holding the slide record.
    package var memberIndex: Int

    /// The slide record's index within its member.
    package var recordIndex: Int
  }

  private let members: [KeynoteArchiveSurgeon.Member]

  /// Creates a catalog over `members`.
  package init(members: [KeynoteArchiveSurgeon.Member]) {
    self.members = members
  }

  /// The deck's slides, in presentation order.
  ///
  /// Walks show → slide tree → slide nodes → slide records, resolving the
  /// tree's node references through `KN.SlideNodeArchive` exactly as the
  /// navigation layer does.
  package func orderedSlides() throws -> [Slide] {
    guard let showLocation = try locateFirst(named: "KN.ShowArchive") else {
      throw ArchiveSurgeryError.missingShowArchive
    }
    let show = try KN_ShowArchive(
      serializedBytes: payload(at: showLocation),
      partial: true
    )
    var nodeIdentifiers = show.slideTree.slides.map(\.identifier)
    if show.slideTree.hasRootSlideNode,
      let root = try slideNode(withIdentifier: show.slideTree.rootSlideNode.identifier),
      !root.children.isEmpty
    {
      nodeIdentifiers = root.children.map(\.identifier)
    }
    var slides: [Slide] = []
    for nodeIdentifier in nodeIdentifiers {
      guard let node = try slideNode(withIdentifier: nodeIdentifier), node.hasSlide else {
        throw ArchiveSurgeryError.missingSlideRecord(identifier: nodeIdentifier)
      }
      guard let slideLocation = locate(recordIdentifier: node.slide.identifier) else {
        throw ArchiveSurgeryError.missingSlideRecord(identifier: node.slide.identifier)
      }
      slides.append(
        Slide(
          nodeIdentifier: nodeIdentifier,
          slideIdentifier: node.slide.identifier,
          memberIndex: slideLocation.memberIndex,
          recordIndex: slideLocation.recordIndex
        )
      )
    }
    return slides
  }

  /// The location of the record with `identifier`, if any.
  package func locate(recordIdentifier identifier: UInt64) -> Location? {
    for (memberIndex, member) in members.enumerated() {
      for (recordIndex, record) in member.records.enumerated()
      where record.info.identifier == identifier {
        return Location(memberIndex: memberIndex, recordIndex: recordIndex, payloadIndex: 0)
      }
    }
    return nil
  }

  /// The location of the payload of `name` inside the record with
  /// `identifier`, if both resolve.
  package func locate(recordIdentifier identifier: UInt64, named name: String) throws -> Location? {
    guard var location = locate(recordIdentifier: identifier) else {
      return nil
    }
    let record = members[location.memberIndex].records[location.recordIndex]
    guard
      let payloadIndex = record.resolvedTypes.firstIndex(where: {
        TSPRegistryMapping.messageName(for: $0) == name
      })
    else {
      return nil
    }
    location.payloadIndex = payloadIndex
    return location
  }

  /// The first payload of `name` in archive order, if any.
  package func locateFirst(named name: String) throws -> Location? {
    for (memberIndex, member) in members.enumerated() {
      for (recordIndex, record) in member.records.enumerated() {
        if let payloadIndex = record.resolvedTypes.firstIndex(where: {
          TSPRegistryMapping.messageName(for: $0) == name
        }) {
          return Location(
            memberIndex: memberIndex,
            recordIndex: recordIndex,
            payloadIndex: payloadIndex
          )
        }
      }
    }
    return nil
  }

  /// The payload bytes at `location`.
  private func payload(at location: Location) -> [UInt8] {
    members[location.memberIndex].records[location.recordIndex].payloads[location.payloadIndex]
  }

  /// Decodes the slide node in the record with `identifier`, if present.
  private func slideNode(withIdentifier identifier: UInt64) throws -> KN_SlideNodeArchive? {
    guard
      let location = try locate(
        recordIdentifier: identifier,
        named: "KN.SlideNodeArchive"
      )
    else {
      return nil
    }
    return try KN_SlideNodeArchive(serializedBytes: payload(at: location), partial: true)
  }
}
