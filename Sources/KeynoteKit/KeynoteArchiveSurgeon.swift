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
  internal var metadataPathHint: String?

  /// Parses every `Index/*.iwa` member of `bundle`.
  package init(bundle: KeyBundle) throws {
    self.members = try bundle.indexEntryPaths.map { path in
      guard let entry = bundle.entry(at: path) else {
        return (path: path, records: [])
      }
      return (
        path: path,
        records: try TSPArchiveStream.default.records(
          from: IWAChunkCodec.default.decode(entry.body)
        )
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
    var nextIdentifier = maximumIdentifier() + 1
    let firstIdentifier = nextIdentifier
    try expandSlides(
      to: deck.slides.count,
      in: &bundle,
      nextIdentifier: &nextIdentifier,
      using: &generator
    )
    let slides = try SlideCatalog(members: members).orderedSlides()
    guard slides.count == deck.slides.count else {
      throw ArchiveSurgeryError.slideCountMismatch(expected: deck.slides.count, found: slides.count)
    }
    var mintedMaximum: UInt64 = 0
    var dirtyPaths = Set<String>()
    for (slideIndex, pair) in zip(slides, deck.slides).enumerated() {
      try authorOneSlide(
        pair.1,
        at: pair.0,
        slideIndex: slideIndex,
        into: &bundle,
        nextIdentifier: &nextIdentifier,
        mintedMaximum: &mintedMaximum,
        dirtyPaths: &dirtyPaths,
        using: &generator
      )
    }
    if nextIdentifier > firstIdentifier {
      try bumpLastObjectIdentifier(to: nextIdentifier)
    }
    let buildCount = deck.slides.reduce(0) { $0 + $1.builds.count }
    try UUIDMapVerifier.verify(members: members, expectedBuildCount: buildCount)
    for member in members
    where dirtyPaths.contains(member.path) || nextIdentifier > firstIdentifier {
      let body = IWAChunkCodec.default.encode(
        try TSPArchiveStream.default.serialize(member.records)
      )
      bundle.setBody(body, at: member.path)
    }
  }

  /// Authors a single slide and folds its minted artifacts into the
  /// running bookkeeping for the deck-level write.
  private mutating func authorOneSlide(
    _ spec: AuthoredSlide,
    at location: SlideCatalog.Slide,
    slideIndex: Int,
    into bundle: inout KeyBundle,
    nextIdentifier: inout UInt64,
    mintedMaximum: inout UInt64,
    dirtyPaths: inout Set<String>,
    using generator: inout some RandomNumberGenerator
  ) throws {
    if spec.items.isEmpty {
      try expandTextItems(to: spec.itemCount, at: location, nextIdentifier: &nextIdentifier)
    } else {
      try expandDrawables(
        spec.items,
        at: location,
        into: &bundle,
        nextIdentifier: &nextIdentifier,
        using: &generator
      )
    }
    let minted = try authorSlide(
      spec,
      at: location,
      slideIndex: slideIndex,
      nextIdentifier: &nextIdentifier,
      using: &generator
    )
    dirtyPaths.formUnion(minted.dirtyPaths)
    mintedMaximum = max(mintedMaximum, minted.maximumIdentifier)
    if !minted.uuidEntries.isEmpty {
      try registerUUIDEntries(minted.uuidEntries, slideIdentifier: location.slideIdentifier)
      dirtyPaths.insert(metadataPathHint ?? "")
    }
    for entry in minted.dataEntries {
      bundle.upsertEntry(body: entry.body, at: entry.path)
    }
    if !minted.dataInfos.isEmpty || !minted.componentDataReferences.isEmpty {
      try registerData(
        infos: minted.dataInfos,
        componentReferences: minted.componentDataReferences,
        slideIdentifier: location.slideIdentifier
      )
      dirtyPaths.insert(metadataPathHint ?? "")
    }
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
