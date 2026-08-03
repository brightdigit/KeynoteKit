//
//  KeynoteArchiveSurgeon+ShapeStyle.swift
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
  /// Registry type for `TSWP.ShapeStyleArchive`.
  private static let shapeStyleArchiveType: UInt32 = 2_025

  /// An authored color as the archive's sRGB `TSP.Color`.
  private static func archiveColor(_ color: Color) -> TSP_Color {
    var archived = TSP_Color()
    archived.model = .rgb
    archived.r = Float(color.red)
    archived.g = Float(color.green)
    archived.b = Float(color.blue)
    archived.a = Float(color.opacity)
    archived.rgbspace = .srgb
    return archived
  }

  /// Mints and applies the shape-style fork carrying vertical alignment,
  /// columns, and/or a background fill: a type-2025 variation of the
  /// placeholder's current style, repointing `TSD.ShapeArchive.style` and
  /// the placeholder record's header reference. Returns `nil` when none of
  /// them is set, which keeps unstyled boxes byte-identical to the template.
  internal mutating func applyShapeStyle(
    for item: AuthoredSlide.TextItem,
    at placeholderLocation: SlideCatalog.Location,
    nextIdentifier: inout UInt64,
    minted: inout MintedSlide
  ) throws -> MintedTextStyle? {
    guard item.verticalAlignment != nil || item.columnCount != nil || item.background != nil
    else {
      return nil
    }
    guard let stylesheetIdentifier = try documentStylesheetIdentifier() else {
      throw ArchiveSurgeryError.missingSlideRecord(identifier: 0)
    }
    var placeholder = try KN_PlaceholderArchive(
      serializedBytes: members[placeholderLocation.memberIndex]
        .records[placeholderLocation.recordIndex]
        .payloads[placeholderLocation.payloadIndex],
      partial: true
    )
    let parentIdentifier = placeholder.super.super.style.identifier
    let identifier = nextIdentifier
    nextIdentifier += 1
    let record = try shapeStyleRecord(
      for: item,
      identifier: identifier,
      parentIdentifier: parentIdentifier,
      stylesheetIdentifier: stylesheetIdentifier
    )
    placeholder.super.super.style.identifier = identifier
    members[placeholderLocation.memberIndex].records[placeholderLocation.recordIndex]
      .payloads[placeholderLocation.payloadIndex] = try placeholder.serializedBytes(partial: true)
    replaceRecordHeaderReference(parentIdentifier, with: identifier, at: placeholderLocation)
    minted.maximumIdentifier = max(minted.maximumIdentifier, identifier)
    return MintedTextStyle(
      record: record,
      identifier: identifier,
      parentIdentifier: parentIdentifier
    )
  }

  /// Mints the type-2025 variation. Mirrors the theme's own forks: the
  /// TSWP-level `shapeProperties` carries text-frame overrides (vertical
  /// alignment, columns) and the TSD-level super carries drawable overrides
  /// (the background fill).
  ///
  /// `overrideCount` is a **shared total across both bags**, written
  /// identically into both fields — not a per-bag count. Verified against
  /// every `TSWP.ShapeStyleArchive` in `build_action_B.key`: all 29 have
  /// `overrideCount == super.overrideCount`, including variation 2651764,
  /// which sets a TSD fill plus TSWP alignment and padding and writes 4/4
  /// rather than 1/3. See `research/findings/text_columns.md`.
  private func shapeStyleRecord(
    for item: AuthoredSlide.TextItem,
    identifier: UInt64,
    parentIdentifier: UInt64,
    stylesheetIdentifier: UInt64
  ) throws -> TSPArchiveRecord {
    var style = TSWP_ShapeStyleArchive()
    style.super.super.isVariation = true
    style.super.super.parent.identifier = parentIdentifier
    style.super.super.stylesheet.identifier = stylesheetIdentifier
    var count: UInt32 = 0
    var drawableProperties = TSD_ShapeStylePropertiesArchive()
    if let background = item.background {
      var fill = TSD_FillArchive()
      fill.color = Self.archiveColor(background)
      drawableProperties.fill = fill
      count += 1
    }
    style.super.shapeProperties = drawableProperties
    var properties = TSWP_ShapeStylePropertiesArchive()
    if let alignment = item.verticalAlignment {
      properties.verticalAlignment = alignment.archiveValue
      count += 1
    }
    if let columnCount = item.columnCount {
      var columns = TSWP_ColumnsArchive()
      columns.equalColumns.count = UInt32(columnCount)
      if let gap = item.columnGap {
        columns.equalColumns.gap = try columnGapFraction(fromPoints: gap)
      }
      properties.columns = columns
      count += 1
    }
    style.shapeProperties = properties
    style.overrideCount = count
    style.super.overrideCount = count
    var messageInfo = TSP_MessageInfo()
    messageInfo.type = Self.shapeStyleArchiveType
    messageInfo.version = BuildRecordFactory.version
    messageInfo.objectReferences = [parentIdentifier, stylesheetIdentifier]
    var info = TSP_ArchiveInfo()
    info.identifier = identifier
    info.messageInfos = [messageInfo]
    return TSPArchiveRecord(
      info: info,
      payloads: [try style.serializedBytes(partial: true)]
    )
  }

  /// Converts an authored gutter in points to the archive's gap value: a
  /// dimensionless fraction of the text layout width, which Keynote takes
  /// from the layout master's body placeholder — not the authored frame
  /// (`research/findings/text_columns.md`).
  internal func columnGapFraction(fromPoints points: Double) throws -> Float {
    let width = try templateBodyPlaceholderWidth()
    guard width > 0 else {
      throw ArchiveSurgeryError.invariantViolation(
        "template body placeholder has zero width; cannot convert column gap"
      )
    }
    return Float(points / width)
  }

  /// The layout master's body placeholder width, the denominator of the
  /// column-gap fraction.
  private func templateBodyPlaceholderWidth() throws -> Double {
    for member in members where Self.locatorStem(of: member.path).hasPrefix("TemplateSlide") {
      for record in member.records {
        guard
          let payloadIndex = record.resolvedTypes.firstIndex(where: {
            TSPRegistryMapping.messageName(for: $0) == "KN.PlaceholderArchive"
          })
        else {
          continue
        }
        let placeholder = try KN_PlaceholderArchive(
          serializedBytes: record.payloads[payloadIndex],
          partial: true
        )
        if placeholder.kind == .kKindBodyPlaceholder {
          return Double(placeholder.super.super.super.geometry.size.width)
        }
      }
    }
    throw ArchiveSurgeryError.invariantViolation(
      "no template body placeholder found for column-gap conversion"
    )
  }
}

extension VerticalTextAlignment {
  /// The archive ordinal: 0 top, 1 middle, 2 bottom (theme forks
  /// `kFrameAlignTop`/`kFrameAlignBottom` in the blank template).
  internal var archiveValue: TSWP_ShapeStylePropertiesArchive.VerticalAlignmentType {
    switch self {
    case .top: .kFrameAlignTop
    case .middle: .kFrameAlignMiddle
    case .bottom: .kFrameAlignBottom
    }
  }
}
