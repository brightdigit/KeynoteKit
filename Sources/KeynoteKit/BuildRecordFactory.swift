//
//  BuildRecordFactory.swift
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

/// Mints the `KN.BuildArchive` + `KN.BuildChunkArchive` record pair for one
/// authored build — a field-for-field port of the Python backend's
/// `build_archive_records` (`research/tools/archive_backend.py:28-94`).
package enum BuildRecordFactory {
  /// The minted pair plus the 128-bit uuid shared by the chunk's `buildId`
  /// and the slide component's uuid-map entry.
  package struct MintedBuild {
    /// The `KN.BuildArchive` record.
    package var buildRecord: TSPArchiveRecord

    /// The `KN.BuildChunkArchive` record.
    package var chunkRecord: TSPArchiveRecord

    /// The shared build uuid.
    package var buildUUID: TSP_UUID
  }

  /// The registry type of `KN.BuildArchive`.
  package static let buildArchiveType: UInt32 = 8

  /// The registry type of `KN.BuildChunkArchive`.
  package static let buildChunkArchiveType: UInt32 = 153

  /// The `MessageInfo.version` stamped on every minted record.
  package static let version: [UInt32] = [1, 0, 5]

  /// Mints the record pair for `build`.
  ///
  /// - Parameters:
  ///   - build: The authored build.
  ///   - drawableIdentifier: The target drawable's object identifier.
  ///   - buildIdentifier: The new `KN.BuildArchive` record identifier.
  ///   - chunkIdentifier: The new `KN.BuildChunkArchive` record identifier.
  ///   - generator: Randomness for the uuid and animation seed.
  /// - Returns: The minted pair and uuid.
  /// - Throws: A SwiftProtobuf error if serialization fails.
  package static func mint(
    _ build: AuthoredBuild,
    drawableIdentifier: UInt64,
    buildIdentifier: UInt64,
    chunkIdentifier: UInt64,
    using generator: inout some RandomNumberGenerator
  ) throws -> MintedBuild {
    var uuid = TSP_UUID()
    uuid.lower = UInt64.random(in: .min ... .max, using: &generator)
    uuid.upper = UInt64.random(in: .min ... .max, using: &generator)
    let seed = UInt32.random(in: 0..<0x8000_0000, using: &generator)
    let buildRecord = TSPArchiveRecord(
      info: header(identifier: buildIdentifier, type: buildArchiveType),
      payloads: [
        try buildArchive(build, drawableIdentifier: drawableIdentifier, seed: seed)
          .serializedBytes(partial: true)
      ]
    )
    let chunkRecord = TSPArchiveRecord(
      info: header(identifier: chunkIdentifier, type: buildChunkArchiveType),
      payloads: [
        try chunkArchive(build, buildIdentifier: buildIdentifier, uuid: uuid)
          .serializedBytes(partial: true)
      ]
    )
    return MintedBuild(buildRecord: buildRecord, chunkRecord: chunkRecord, buildUUID: uuid)
  }

  /// A minted record's header: one `MessageInfo`, no references.
  private static func header(identifier: UInt64, type: UInt32) -> TSP_ArchiveInfo {
    var messageInfo = TSP_MessageInfo()
    messageInfo.type = type
    messageInfo.version = version
    var info = TSP_ArchiveInfo()
    info.identifier = identifier
    info.messageInfos = [messageInfo]
    return info
  }

  /// The `KN.BuildArchive` payload.
  private static func buildArchive(
    _ build: AuthoredBuild,
    drawableIdentifier: UInt64,
    seed: UInt32
  ) throws -> KN_BuildArchive {
    var animation = KN_AnimationAttributesArchive()
    animation.animationType = build.kind.rawValue
    animation.delay = build.delay
    animation.duration = build.duration
    animation.effect = build.effect
    if let direction = build.direction {
      animation.direction = direction
    }
    animation.randomNumberSeed = seed
    animation.writingDirectionIsRtl = false

    var attributes = KN_BuildAttributesArchive()
    attributes.chartRotation3D = 60.0
    if build.kind == .action {
      attributes.actionAcceleration = .kEaseBoth
      attributes.actionMotionPathSource = pathSource(for: build)
    } else {
      attributes.customDeliveryOption = .kDeliveryOptionForward
      attributes.customTextDelivery = .kTextDeliveryByObject
    }
    attributes.animationAttributes = animation
    attributes.eventTrigger = 1

    var archive = KN_BuildArchive()
    archive.attributes = attributes
    archive.chunkIDSeed = 1
    archive.delivery = build.delivery ?? "All at Once"
    archive.drawable.identifier = drawableIdentifier
    archive.duration = 0.0
    return archive
  }

  /// The `KN.BuildChunkArchive` payload.
  private static func chunkArchive(
    _ build: AuthoredBuild,
    buildIdentifier: UInt64,
    uuid: TSP_UUID
  ) -> KN_BuildChunkArchive {
    var chunk = KN_BuildChunkArchive()
    chunk.automatic = false
    chunk.build.identifier = buildIdentifier
    chunk.buildChunkIdentifier.buildChunkID = 1
    chunk.buildChunkIdentifier.buildID = uuid
    chunk.buildID = uuid
    chunk.delay = build.delay
    chunk.duration = build.duration
    chunk.referent = true
    return chunk
  }

  /// The Action motion-path source.
  private static func pathSource(for build: AuthoredBuild) -> TSD_PathSourceArchive {
    guard let path = build.motionPath else {
      return TSD_PathSourceArchive()
    }
    var subpath = TSD_EditableBezierPathSourceArchive.Subpath()
    subpath.closed = false
    subpath.nodes = path.points.map { point in
      var node = TSD_EditableBezierPathSourceArchive.Node()
      var tspPoint = TSP_Point()
      tspPoint.x = Float(point.x)
      tspPoint.y = Float(point.y)
      node.inControlPoint = tspPoint
      node.nodePoint = tspPoint
      node.outControlPoint = tspPoint
      node.type = .sharp
      return node
    }
    var bezier = TSD_EditableBezierPathSourceArchive()
    bezier.naturalSize.width = Float(path.naturalWidth)
    bezier.naturalSize.height = Float(path.naturalHeight)
    bezier.subpaths = [subpath]
    // The goldens carry no flip fields: keynote-parser silently dropped the
    // spec's nested horizontalFlip/verticalFlip keys, so they stay absent.
    var source = TSD_PathSourceArchive()
    source.editableBezierPathSource = bezier
    return source
  }
}
