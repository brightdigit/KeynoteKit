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
    var objectIdentifier: UInt64
    var path: String
    var body: [UInt8]
    var dataInfo: TSP_DataInfo
  }

  /// Registry type for `TSD.ImageArchive`.
  private static let imageArchiveType: UInt32 = 3_005

  /// Ensures `drawablesZOrder` matches `items`: text slots clone the body
  /// placeholder; image slots mint a `TSD.ImageArchive` + `Data/` member.
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
    var pendingData: [(path: String, body: [UInt8])] = []
    var pendingInfos: [TSP_DataInfo] = []
    var pendingComponentRefs: [(dataIdentifier: UInt64, objectIdentifier: UInt64)] = []
    for item in items {
      try appendDrawable(
        item,
        to: &slide,
        at: location,
        nextIdentifier: &nextIdentifier,
        pendingData: &pendingData,
        pendingInfos: &pendingInfos,
        pendingComponentRefs: &pendingComponentRefs,
        using: &generator
      )
    }
    members[location.memberIndex].records[location.recordIndex].payloads[0] =
      try slide.serializedBytes(partial: true)
    for entry in pendingData {
      bundle.upsertEntry(body: entry.body, at: entry.path)
    }
    if !pendingInfos.isEmpty {
      try registerData(
        infos: pendingInfos,
        componentReferences: pendingComponentRefs,
        slideIdentifier: location.slideIdentifier
      )
    }
  }

  /// Appends one authored drawable into `slide`'s z-order and pending data.
  private mutating func appendDrawable(
    _ item: AuthoredSlide.DrawableItem,
    to slide: inout KN_SlideArchive,
    at location: SlideCatalog.Slide,
    nextIdentifier: inout UInt64,
    pendingData: inout [(path: String, body: [UInt8])],
    pendingInfos: inout [TSP_DataInfo],
    pendingComponentRefs: inout [(dataIdentifier: UInt64, objectIdentifier: UInt64)],
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
      appendHeaderReferences([minted.objectIdentifier], toRecordAt: location)
      var reference = TSP_Reference()
      reference.identifier = minted.objectIdentifier
      slide.drawablesZOrder.append(reference)
      pendingData.append((minted.path, minted.body))
      pendingInfos.append(minted.dataInfo)
      pendingComponentRefs.append((minted.dataInfo.identifier, minted.objectIdentifier))
    }
  }

  /// Mints a `TSD.ImageArchive` wired to a new `Data/` member.
  private mutating func mintImageDrawable(
    _ item: AuthoredSlide.ImageItem,
    parentSlideIdentifier: UInt64,
    nextIdentifier: inout UInt64,
    using generator: inout some RandomNumberGenerator
  ) throws -> MintedImage {
    let objectIdentifier = nextIdentifier
    nextIdentifier += 1
    let dataIdentifier = try nextDataIdentifier()
    let uuid = uuidString(using: &generator)
    let ext = item.fileExtension.isEmpty ? "jpg" : item.fileExtension
    let preferredName = "kn-\(uuid).\(ext)"
    let fileName = "kn-\(uuid)-\(dataIdentifier).\(ext)"

    var dataInfo = TSP_DataInfo()
    dataInfo.identifier = dataIdentifier
    dataInfo.digest = Data(SHA1Digest.hash(item.data))
    dataInfo.preferredFileName = preferredName
    dataInfo.fileName = fileName

    let image = try buildImageArchive(
      item,
      dataIdentifier: dataIdentifier,
      parentSlideIdentifier: parentSlideIdentifier
    )
    let record = try imageRecord(
      image,
      objectIdentifier: objectIdentifier,
      dataIdentifier: dataIdentifier,
      parentSlideIdentifier: parentSlideIdentifier
    )
    return MintedImage(
      record: record,
      objectIdentifier: objectIdentifier,
      path: "Data/\(fileName)",
      body: item.data,
      dataInfo: dataInfo
    )
  }

  /// Builds the `TSD.ImageArchive` payload for an authored image item.
  private func buildImageArchive(
    _ item: AuthoredSlide.ImageItem,
    dataIdentifier: UInt64,
    parentSlideIdentifier: UInt64
  ) throws -> TSD_ImageArchive {
    let naturalWidth = Float(item.naturalWidth ?? item.width ?? 200)
    let naturalHeight = Float(item.naturalHeight ?? item.height ?? 200)
    let frameWidth = Float(item.width ?? item.naturalWidth ?? 200)
    let frameHeight = Float(item.height ?? item.naturalHeight ?? 200)

    var geometry = TSD_GeometryArchive()
    geometry.position.x = Float(item.x)
    geometry.position.y = Float(item.y)
    geometry.size.width = frameWidth
    geometry.size.height = frameHeight

    var drawable = TSD_DrawableArchive()
    drawable.geometry = geometry
    drawable.parent.identifier = parentSlideIdentifier

    var image = TSD_ImageArchive()
    image.super = drawable
    image.data.identifier = dataIdentifier
    image.naturalSize.width = naturalWidth
    image.naturalSize.height = naturalHeight
    image.originalSize.width = frameWidth
    image.originalSize.height = frameHeight
    image.flags = 3
    if let styleIdentifier = try mediaStyleIdentifier() {
      image.style.identifier = styleIdentifier
    }
    return image
  }

  /// Wraps an image archive in a TSP record with the right references.
  private func imageRecord(
    _ image: TSD_ImageArchive,
    objectIdentifier: UInt64,
    dataIdentifier: UInt64,
    parentSlideIdentifier: UInt64
  ) throws -> TSPArchiveRecord {
    var messageInfo = TSP_MessageInfo()
    messageInfo.type = Self.imageArchiveType
    messageInfo.version = BuildRecordFactory.version
    messageInfo.dataReferences = [dataIdentifier]
    messageInfo.objectReferences =
      image.hasStyle
      ? [image.style.identifier, parentSlideIdentifier] : [parentSlideIdentifier]
    var info = TSP_ArchiveInfo()
    info.identifier = objectIdentifier
    info.messageInfos = [messageInfo]
    return TSPArchiveRecord(info: info, payloads: [try image.serializedBytes(partial: true)])
  }
}
