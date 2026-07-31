//
//  KeynoteArchiveSurgeon+ImageRecords.swift
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
package import KeynoteKitProtobuf

extension KeynoteArchiveSurgeon {
  /// Registry type for `TSD.ImageArchive`.
  private static let imageArchiveType: UInt32 = 3_005

  /// Registry type for `TSD.StandinCaptionArchive`.
  private static let standinCaptionArchiveType: UInt32 = 3_097

  /// Closed rectangle path in image pixel space, matching Keynote's traced
  /// path for a freshly inserted photo.
  internal static func rectanglePath(width: Float, height: Float) -> TSP_Path {
    func element(_ type: TSP_Path.ElementType, _ points: (Float, Float)...) -> TSP_Path.Element {
      var element = TSP_Path.Element()
      element.type = type
      element.points = points.map { point in
        var converted = TSP_Point()
        converted.x = point.0
        converted.y = point.1
        return converted
      }
      return element
    }
    var path = TSP_Path()
    path.elements = [
      element(.moveTo, (0, 0)),
      element(.lineTo, (width, 0)),
      element(.lineTo, (width, height)),
      element(.lineTo, (0, height)),
      element(.closeSubpath),
      element(.moveTo, (0, 0)),
    ]
    return path
  }

  /// Builds the `TSD.ImageArchive` payload for an authored image item.
  internal func buildImageArchive(
    _ item: AuthoredSlide.ImageItem,
    identifiers: ImageDrawableIdentifiers,
    frameSize: (width: Float, height: Float),
    naturalSize: (width: Float, height: Float)
  ) -> TSD_ImageArchive {
    var geometry = TSD_GeometryArchive()
    geometry.position.x = Float(item.x)
    geometry.position.y = Float(item.y)
    geometry.size.width = frameSize.width
    geometry.size.height = frameSize.height
    geometry.flags = 3

    var wrap = TSD_ExteriorTextWrapArchive()
    wrap.type = 4
    wrap.direction = 2
    wrap.fitType = 1
    wrap.isHtmlWrap = false
    wrap.margin = 12
    wrap.alphaThreshold = 0.5

    var drawable = TSD_DrawableArchive()
    drawable.geometry = geometry
    drawable.parent.identifier = identifiers.parentSlide
    drawable.title.identifier = identifiers.titleCaption
    drawable.caption.identifier = identifiers.caption
    drawable.titleHidden = false
    drawable.captionHidden = false
    drawable.aspectRatioLocked = true
    drawable.accessibilityDescription = ""
    drawable.exteriorTextWrap = wrap

    var image = TSD_ImageArchive()
    image.super = drawable
    image.data.identifier = identifiers.data
    image.naturalSize.width = naturalSize.width
    image.naturalSize.height = naturalSize.height
    image.originalSize.width = naturalSize.width
    image.originalSize.height = naturalSize.height
    image.flags = 0
    image.interpretsUntaggedImageDataAsGeneric = false
    image.tracedPath = Self.rectanglePath(width: naturalSize.width, height: naturalSize.height)
    if let style = identifiers.style {
      image.style.identifier = style
    }
    return image
  }

  /// `DataInfo` row for authored image bytes: SHA-1 digest, materialized
  /// length, and pixel-size image data attributes — Keynote aborts in
  /// TSPersistence when these are missing.
  internal func imageDataInfo(
    for item: AuthoredSlide.ImageItem,
    dataIdentifier: UInt64,
    fileName: String,
    preferredFileName: String,
    naturalSize: (width: Float, height: Float)
  ) -> TSP_DataInfo {
    var imageAttributes = TSD_ImageDataAttributes()
    imageAttributes.pixelSize.width = naturalSize.width
    imageAttributes.pixelSize.height = naturalSize.height
    imageAttributes.shouldBeInterpretedAsGenericIfUntagged = false
    var attributes = TSP_DataAttributes()
    attributes.TSD_ImageDataAttributes_imageDataAttributes = imageAttributes

    var dataInfo = TSP_DataInfo()
    dataInfo.identifier = dataIdentifier
    dataInfo.digest = Data(SHA1Digest.hash(item.data))
    dataInfo.preferredFileName = preferredFileName
    dataInfo.fileName = fileName
    dataInfo.materializedLength = UInt64(item.data.count)
    dataInfo.attributes = attributes
    return dataInfo
  }

  /// Empty `TSD.StandinCaptionArchive` used for image title/caption slots.
  internal func standinCaptionRecord(identifier: UInt64) throws -> TSPArchiveRecord {
    var messageInfo = TSP_MessageInfo()
    messageInfo.type = Self.standinCaptionArchiveType
    messageInfo.version = BuildRecordFactory.version
    var info = TSP_ArchiveInfo()
    info.identifier = identifier
    info.messageInfos = [messageInfo]
    return TSPArchiveRecord(
      info: info,
      payloads: [try TSD_StandinCaptionArchive().serializedBytes(partial: true)]
    )
  }

  /// Wraps an image archive in a TSP record with the right references.
  internal func imageRecord(
    _ image: TSD_ImageArchive,
    identifiers: ImageDrawableIdentifiers
  ) throws -> TSPArchiveRecord {
    var messageInfo = TSP_MessageInfo()
    messageInfo.type = Self.imageArchiveType
    messageInfo.version = BuildRecordFactory.version
    messageInfo.dataReferences = [identifiers.data]
    var objectReferences = [identifiers.titleCaption, identifiers.caption]
    if image.hasStyle {
      objectReferences.append(image.style.identifier)
    }
    messageInfo.objectReferences = objectReferences
    var info = TSP_ArchiveInfo()
    info.identifier = identifiers.object
    info.messageInfos = [messageInfo]
    return TSPArchiveRecord(info: info, payloads: [try image.serializedBytes(partial: true)])
  }
}
