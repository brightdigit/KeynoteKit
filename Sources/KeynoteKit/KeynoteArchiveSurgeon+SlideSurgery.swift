//
//  KeynoteArchiveSurgeon+SlideSurgery.swift
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

extension KeynoteArchiveSurgeon {
  /// The result of authoring one slide.
  internal struct MintedSlide {
    internal var uuidEntries: [TSP_ObjectUUIDMapEntry] = []
    internal var maximumIdentifier: UInt64 = 0
    internal var dirtyPaths: Set<String> = []
    internal var dataEntries: [(path: String, body: [UInt8])] = []
    internal var dataInfos: [TSP_DataInfo] = []
    internal var componentDataReferences: [TSP_ComponentDataReference] = []
  }

  /// One slide's freshly minted records and identifiers.
  private struct MintedBatch {
    var buildRecords: [TSPArchiveRecord] = []
    var chunkRecords: [TSPArchiveRecord] = []
    var buildIdentifiers: [UInt64] = []
    var chunkIdentifiers: [UInt64] = []
  }

  /// Authors one slide: transition direction, minted build/chunk records,
  /// slide references, and slide-node build flags.
  internal mutating func authorSlide(
    _ spec: AuthoredSlide,
    at location: SlideCatalog.Slide,
    slideIndex: Int,
    nextIdentifier: inout UInt64,
    using generator: inout some RandomNumberGenerator
  ) throws -> MintedSlide {
    var minted = MintedSlide()
    var slideArchive = try KN_SlideArchive(
      serializedBytes: members[location.memberIndex].records[location.recordIndex].payloads[0],
      partial: true
    )
    let drawables = slideArchive.drawablesZOrder.map(\.identifier)
    guard drawables.count == spec.itemCount else {
      throw ArchiveSurgeryError.drawableCountMismatch(
        slideIndex: slideIndex,
        items: spec.itemCount,
        drawables: drawables.count
      )
    }
    if try applyTransition(spec, to: &slideArchive, slideIndex: slideIndex) {
      minted.dirtyPaths.insert(members[location.memberIndex].path)
      try flagSlideNodeTransition(at: location, dirtyPaths: &minted.dirtyPaths)
    }
    if !spec.items.isEmpty {
      try applyDrawableItems(
        spec.items,
        to: &slideArchive,
        at: location,
        slideIndex: slideIndex,
        nextIdentifier: &nextIdentifier,
        minted: &minted,
        using: &generator
      )
      minted.dirtyPaths.insert(members[location.memberIndex].path)
    }
    let batch = try mintBuilds(
      spec.builds,
      drawables: drawables,
      slideIndex: slideIndex,
      slideArchive: &slideArchive,
      minted: &minted,
      nextIdentifier: &nextIdentifier,
      using: &generator
    )
    members[location.memberIndex].records[location.recordIndex].payloads[0] =
      try slideArchive.serializedBytes(partial: true)
    if !spec.builds.isEmpty {
      minted.dirtyPaths.insert(members[location.memberIndex].path)
      // Python splices all build ids, then all chunk ids, at index 1.
      insertMintedRecords(
        batch.buildRecords + batch.chunkRecords,
        newIdentifiers: batch.buildIdentifiers + batch.chunkIdentifiers,
        at: location
      )
      try flagSlideNode(at: location, buildCount: spec.builds.count, dirtyPaths: &minted.dirtyPaths)
    }
    return minted
  }

  /// Mints all of a slide's builds, wiring the slide archive's `builds` /
  /// `buildChunks` references and the uuid-map entries as it goes.
  private mutating func mintBuilds(
    _ builds: [AuthoredBuild],
    drawables: [UInt64],
    slideIndex: Int,
    slideArchive: inout KN_SlideArchive,
    minted: inout MintedSlide,
    nextIdentifier: inout UInt64,
    using generator: inout some RandomNumberGenerator
  ) throws -> MintedBatch {
    var batch = MintedBatch()
    for build in builds {
      guard drawables.indices.contains(build.targetIndex) else {
        throw ArchiveSurgeryError.targetOutOfRange(
          slideIndex: slideIndex,
          targetIndex: build.targetIndex
        )
      }
      let buildIdentifier = nextIdentifier
      let chunkIdentifier = nextIdentifier + 1
      nextIdentifier += 2
      let mint = try BuildRecordFactory.mint(
        build,
        drawableIdentifier: drawables[build.targetIndex],
        buildIdentifier: buildIdentifier,
        chunkIdentifier: chunkIdentifier,
        using: &generator
      )
      batch.buildRecords.append(mint.buildRecord)
      batch.chunkRecords.append(mint.chunkRecord)
      batch.buildIdentifiers.append(buildIdentifier)
      batch.chunkIdentifiers.append(chunkIdentifier)
      var entry = TSP_ObjectUUIDMapEntry()
      entry.identifier = buildIdentifier
      entry.uuid = mint.buildUUID
      minted.uuidEntries.append(entry)
      slideArchive.builds.append(reference(buildIdentifier))
      slideArchive.buildChunks.append(reference(chunkIdentifier))
      minted.maximumIdentifier = max(minted.maximumIdentifier, chunkIdentifier)
    }
    return batch
  }

  /// Inserts minted records after the slide record and splices their ids
  /// into the slide record's `objectReferences` at index 1, matching Python.
  private mutating func insertMintedRecords(
    _ records: [TSPArchiveRecord],
    newIdentifiers: [UInt64],
    at location: SlideCatalog.Slide
  ) {
    members[location.memberIndex].records.insert(
      contentsOf: records,
      at: location.recordIndex + 1
    )
    var info = members[location.memberIndex].records[location.recordIndex].info
    var references = info.messageInfos[0].objectReferences
    references.insert(contentsOf: newIdentifiers, at: min(1, references.count))
    info.messageInfos[0].objectReferences = references
    members[location.memberIndex].records[location.recordIndex].info = info
  }

  /// A `TSP.Reference` to `identifier`.
  private func reference(_ identifier: UInt64) -> TSP_Reference {
    var reference = TSP_Reference()
    reference.identifier = identifier
    return reference
  }

  /// Applies the spec's transition fields; true when anything changed.
  private func applyTransition(
    _ spec: AuthoredSlide,
    to slideArchive: inout KN_SlideArchive,
    slideIndex: Int
  ) throws -> Bool {
    guard spec.transition != nil || spec.transitionDirection != nil else {
      return false
    }
    guard slideArchive.hasTransition, slideArchive.transition.hasAttributes else {
      throw ArchiveSurgeryError.missingTransitionPath(slideIndex: slideIndex)
    }
    if let transition = spec.transition {
      var animation = slideArchive.transition.attributes.animationAttributes
      animation.animationType = "Transition"
      animation.effect = transition.effect
      animation.duration = transition.duration
      animation.delay = transition.delay
      animation.isAutomatic = transition.autoAdvance
      slideArchive.transition.attributes.animationAttributes = animation
    }
    if let direction = spec.transitionDirection {
      slideArchive.transition.attributes.animationAttributes.direction = direction
    }
    return true
  }
}
