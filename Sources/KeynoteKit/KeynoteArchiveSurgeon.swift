//
//  KeynoteArchiveSurgeon.swift
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

/// Applies an ``AuthoredDeck`` to a base `.key` bundle by archive surgery —
/// the port of Python `archive_backend.author_unpacked`
/// (`research/tools/archive_backend.py:182-276`), preserving its exact order
/// of operations so differential tests against the goldens stay meaningful.
///
/// The write path never requires a running Keynote.
package struct KeynoteArchiveSurgeon {
  /// One parsed `Index/*.iwa` member.
  package typealias Member = (path: String, records: [TSPArchiveRecord])

  /// The parsed members, in archive order.
  package internal(set) var members: [Member]

  /// The member path holding `TSP.PackageMetadata`, once discovered.
  private var metadataPathHint: String?

  /// Parses every `Index/*.iwa` member of `bundle`.
  package init(bundle: KeyBundle) throws {
    self.members = try bundle.indexEntryPaths.map { path in
      guard let entry = bundle.entry(at: path) else {
        return (path: path, records: [])
      }
      return (
        path: path, records: try TSPArchiveStream.records(from: IWAChunkCodec.decode(entry.body))
      )
    }
  }

  /// Authors `deck` into the parsed members and writes them back to `bundle`.
  ///
  /// - Parameters:
  ///   - deck: The content to author.
  ///   - bundle: The bundle to mutate.
  ///   - generator: Randomness for build uuids and animation seeds.
  /// - Throws: ``ArchiveSurgeryError`` on a base-document mismatch or
  ///   invariant violation; layer errors otherwise.
  package mutating func author(
    _ deck: AuthoredDeck,
    into bundle: inout KeyBundle,
    using generator: inout some RandomNumberGenerator
  ) throws {
    let slides = try SlideCatalog(members: members).orderedSlides()
    guard slides.count == deck.slides.count else {
      throw ArchiveSurgeryError.slideCountMismatch(expected: deck.slides.count, found: slides.count)
    }
    var nextIdentifier = maximumIdentifier() + 1
    let firstIdentifier = nextIdentifier
    var mintedMaximum: UInt64 = 0
    var dirtyPaths = Set<String>()
    for (slideIndex, pair) in zip(slides, deck.slides).enumerated() {
      let minted = try authorSlide(
        pair.1,
        at: pair.0,
        slideIndex: slideIndex,
        nextIdentifier: &nextIdentifier,
        using: &generator
      )
      dirtyPaths.formUnion(minted.dirtyPaths)
      mintedMaximum = max(mintedMaximum, minted.maximumIdentifier)
      if !minted.uuidEntries.isEmpty {
        try registerUUIDEntries(minted.uuidEntries, slideIdentifier: pair.0.slideIdentifier)
        dirtyPaths.insert(metadataPathHint ?? "")
      }
    }
    if nextIdentifier > firstIdentifier {
      try bumpLastObjectIdentifier(to: nextIdentifier)
    }
    let buildCount = deck.slides.reduce(0) { $0 + $1.builds.count }
    try UUIDMapVerifier.verify(members: members, expectedBuildCount: buildCount)
    for member in members
    where dirtyPaths.contains(member.path) || nextIdentifier > firstIdentifier {
      let body = IWAChunkCodec.encode(try TSPArchiveStream.serialize(member.records))
      bundle.setBody(body, at: member.path)
    }
  }

  // MARK: - Package metadata

  /// Appends uuid-map entries to the slide's component.
  private mutating func registerUUIDEntries(
    _ entries: [TSP_ObjectUUIDMapEntry],
    slideIdentifier: UInt64
  ) throws {
    try withPackageMetadata { metadata in
      guard
        let componentIndex = metadata.components.firstIndex(where: {
          $0.identifier == slideIdentifier
        })
      else {
        throw ArchiveSurgeryError.missingSlideComponent(slideIdentifier: slideIdentifier)
      }
      let locator = metadata.components[componentIndex].locator
      guard locator.isEmpty || locator == "Slide-\(slideIdentifier)" else {
        throw ArchiveSurgeryError.unexpectedComponentLocator(locator)
      }
      metadata.components[componentIndex].objectUuidMapEntries.append(contentsOf: entries)
    }
  }

  /// Raises `lastObjectIdentifier` to `value` when it sits below it.
  private mutating func bumpLastObjectIdentifier(to value: UInt64) throws {
    try withPackageMetadata { metadata in
      if metadata.hasLastObjectIdentifier, metadata.lastObjectIdentifier < value {
        metadata.lastObjectIdentifier = value
      }
    }
  }

  /// Decodes, mutates, and re-serializes the single `TSP.PackageMetadata`.
  private mutating func withPackageMetadata(
    _ mutate: (inout TSP_PackageMetadata) throws -> Void
  ) throws {
    guard
      let location = try SlideCatalog(members: members)
        .locateFirst(named: "TSP.PackageMetadata")
    else {
      throw ArchiveSurgeryError.missingSlideComponent(slideIdentifier: 0)
    }
    var metadata = try TSP_PackageMetadata(
      serializedBytes: members[location.memberIndex]
        .records[location.recordIndex].payloads[location.payloadIndex],
      partial: true
    )
    try mutate(&metadata)
    members[location.memberIndex].records[location.recordIndex]
      .payloads[location.payloadIndex] = try metadata.serializedBytes(partial: true)
    metadataPathHint = members[location.memberIndex].path
  }

  /// The highest object identifier referenced anywhere in the document —
  /// Python's `_identifier_values` high-water scan.
  private func maximumIdentifier() -> UInt64 {
    var maximum: UInt64 = 0
    for member in members {
      for record in member.records {
        maximum = max(maximum, record.info.identifier)
        for messageInfo in record.info.messageInfos {
          maximum = messageInfo.objectReferences.reduce(maximum, max)
          maximum = messageInfo.dataReferences.reduce(maximum, max)
        }
      }
    }
    return maximum
  }
}
