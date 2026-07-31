//
//  KeynoteArchiveSurgeon+ImageSupply.swift
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

import Foundation
package import IWAFraming
package import KeynoteKitProtobuf

extension KeynoteArchiveSurgeon {
  /// One minted image drawable plus its zip / metadata bookkeeping.
  private struct MintedImage {
    var record: TSPArchiveRecord
    var titleCaptionRecord: TSPArchiveRecord
    var captionRecord: TSPArchiveRecord
    var identifiers: ImageDrawableIdentifiers
    var dataPath: String
    var body: [UInt8]
    var dataInfo: TSP_DataInfo
    var styleReference: (ownerStem: String, objectIdentifier: UInt64)?
  }

  /// Zip / metadata registrations accumulated while expanding drawables.
  private struct PendingRegistrations {
    var data: [(path: String, body: [UInt8])] = []
    var infos: [TSP_DataInfo] = []
    var componentReferences: [TSP_ComponentDataReference] = []
    var externalReferences: [(ownerStem: String, objectIdentifier: UInt64)] = []
  }

  /// Ensures `drawablesZOrder` matches `items`: text slots clone the body
  /// placeholder; image slots mint a `TSD.ImageArchive` + `Data/` members.
  internal mutating func expandDrawables(
    _ items: [AuthoredSlide.DrawableItem],
    at location: SlideCatalog.Slide,
    into bundle: inout KeyBundle,
    nextIdentifier: inout UInt64,
    using generator: inout some RandomNumberGenerator
  ) throws {
    var slide = try KN_SlideArchive(
      serializedBytes: members[location.memberIndex].records[location.recordIndex].payloads[0],
      partial: true
    )
    slide.drawablesZOrder.removeAll()
    let existingRecordIdentifiers = Set(
      members[location.memberIndex].records.map(\.info.identifier)
    )
    var pending = PendingRegistrations()
    for item in items {
      try appendDrawable(
        item,
        to: &slide,
        at: location,
        nextIdentifier: &nextIdentifier,
        pending: &pending,
        using: &generator
      )
    }
    members[location.memberIndex].records[location.recordIndex].payloads[0] =
      try slide.serializedBytes(partial: true)
    var uuidEntries: [TSP_ObjectUUIDMapEntry] = []
    for record in members[location.memberIndex].records
    where !existingRecordIdentifiers.contains(record.info.identifier) {
      var entry = TSP_ObjectUUIDMapEntry()
      entry.identifier = record.info.identifier
      entry.uuid.lower = UInt64.random(in: .min ... .max, using: &generator)
      entry.uuid.upper = UInt64.random(in: .min ... .max, using: &generator)
      uuidEntries.append(entry)
    }
    try registerUUIDEntries(uuidEntries, slideIdentifier: location.slideIdentifier)
    for entry in pending.data {
      bundle.upsertEntry(body: entry.body, at: entry.path)
    }
    if !pending.infos.isEmpty {
      try registerData(
        infos: pending.infos,
        componentReferences: pending.componentReferences,
        slideIdentifier: location.slideIdentifier
      )
    }
    try registerExternalReferences(
      pending.externalReferences,
      slideIdentifier: location.slideIdentifier
    )
  }

  /// Appends one authored drawable into `slide`'s z-order and pending data.
  private mutating func appendDrawable(
    _ item: AuthoredSlide.DrawableItem,
    to slide: inout KN_SlideArchive,
    at location: SlideCatalog.Slide,
    nextIdentifier: inout UInt64,
    pending: inout PendingRegistrations,
    using generator: inout some RandomNumberGenerator
  ) throws {
    switch item {
    case .text:
      let clonedIdentifier = try cloneBodyPlaceholder(
        of: slide,
        at: location,
        nextIdentifier: &nextIdentifier
      )
      var reference = TSP_Reference()
      reference.identifier = clonedIdentifier
      slide.drawablesZOrder.append(reference)
    case .image(let imageItem):
      let minted = try mintImageDrawable(
        imageItem,
        parentSlideIdentifier: location.slideIdentifier,
        nextIdentifier: &nextIdentifier,
        using: &generator
      )
      members[location.memberIndex].records.append(minted.record)
      members[location.memberIndex].records.append(minted.titleCaptionRecord)
      members[location.memberIndex].records.append(minted.captionRecord)
      appendHeaderReferences([minted.identifiers.object], toRecordAt: location)
      var reference = TSP_Reference()
      reference.identifier = minted.identifiers.object
      slide.drawablesZOrder.append(reference)
      slide.ownedDrawables.append(reference)
      pending.data.append((minted.dataPath, minted.body))
      pending.infos.append(minted.dataInfo)
      pending.componentReferences.append(
        .singleUse(
          dataIdentifier: minted.dataInfo.identifier,
          objectIdentifier: minted.identifiers.object
        )
      )
      if let styleReference = minted.styleReference {
        pending.externalReferences.append(styleReference)
      }
    }
  }

  /// Mints a `TSD.ImageArchive` wired to a single full-size `Data/` member.
  ///
  /// Matches Keynote's insert-image shape: no mask, `flags = 0`, no thumbnail
  /// data, standin title/caption, photo media style, and a `DataInfo` carrying
  /// `materializedLength` plus pixel-size image data attributes.
  private mutating func mintImageDrawable(
    _ item: AuthoredSlide.ImageItem,
    parentSlideIdentifier: UInt64,
    nextIdentifier: inout UInt64,
    using generator: inout some RandomNumberGenerator
  ) throws -> MintedImage {
    let style = try mediaStyle()
    let identifiers = ImageDrawableIdentifiers(
      object: nextIdentifier,
      titleCaption: nextIdentifier + 1,
      caption: nextIdentifier + 2,
      data: try nextDataIdentifier(),
      parentSlide: parentSlideIdentifier,
      style: style?.identifier
    )
    nextIdentifier += 3

    let uuid = uuidString(using: &generator)
    let ext = item.fileExtension.isEmpty ? "jpg" : item.fileExtension
    let preferredName = "kn-\(uuid).\(ext)"
    let fileName = "kn-\(uuid)-\(identifiers.data).\(ext)"

    let frameSize = (
      width: Float(item.width ?? item.naturalWidth ?? 200),
      height: Float(item.height ?? item.naturalHeight ?? 200)
    )
    let naturalSize = (
      width: Float(item.naturalWidth ?? item.width ?? 200),
      height: Float(item.naturalHeight ?? item.height ?? 200)
    )

    let image = buildImageArchive(
      item,
      identifiers: identifiers,
      frameSize: frameSize,
      naturalSize: naturalSize
    )
    return MintedImage(
      record: try imageRecord(image, identifiers: identifiers),
      titleCaptionRecord: try standinCaptionRecord(identifier: identifiers.titleCaption),
      captionRecord: try standinCaptionRecord(identifier: identifiers.caption),
      identifiers: identifiers,
      dataPath: "Data/\(fileName)",
      body: item.data,
      dataInfo: imageDataInfo(
        for: item,
        dataIdentifier: identifiers.data,
        fileName: fileName,
        preferredFileName: preferredName,
        naturalSize: naturalSize
      ),
      styleReference: style.map { (ownerStem: $0.ownerStem, objectIdentifier: $0.identifier) }
    )
  }
}
