//
//  KeynoteArchiveSurgeon+CharacterStyle.swift
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
  /// Registry type for `TSWP.ParagraphStyleArchive`.
  private static let paragraphStyleArchiveType: UInt32 = 2_022

  /// Character-style property bag for a set of authored fields, plus the
  /// number of overridden properties (`overrideCount` on the minted style).
  /// Color carries `tsdFill` alongside `fontColor` — modern Keynote paints
  /// glyphs with the fill and ignores the legacy color alone.
  internal static func characterStyleProperties(
    fontName: String?,
    fontSize: Double?,
    isBold: Bool?,
    isItalic: Bool?,
    color: TextColor?
  ) -> (bag: TSWP_CharacterStylePropertiesArchive, count: UInt32) {
    var properties = TSWP_CharacterStylePropertiesArchive()
    var count: UInt32 = 0
    if let isBold {
      properties.bold = isBold
      count += 1
    }
    if let isItalic {
      properties.italic = isItalic
      count += 1
    }
    if let fontSize {
      properties.fontSize = Float(fontSize)
      count += 1
    }
    if let fontName {
      properties.fontName = fontName
      count += 1
    }
    if let color {
      var tspColor = TSP_Color()
      tspColor.model = .rgb
      tspColor.r = Float(color.red)
      tspColor.g = Float(color.green)
      tspColor.b = Float(color.blue)
      tspColor.a = Float(color.alpha)
      tspColor.rgbspace = .srgb
      properties.fontColor = tspColor
      var fill = TSD_FillArchive()
      fill.color = tspColor
      properties.tsdFill = fill
      count += 2
    }
    return (properties, count)
  }

  /// Mints the forked paragraph-style variation carrying an item's formatting.
  ///
  /// Matches how Keynote itself styles a whole text item: a
  /// `TSWP.ParagraphStyleArchive` with `isVariation`, `parent` = the storage's
  /// current paragraph style, `stylesheet` super, and character properties.
  /// Color must carry `tsdFill` alongside `fontColor` — modern Keynote paints
  /// glyphs with the fill and ignores the legacy color alone.
  internal func paragraphStyleRecord(
    for item: AuthoredSlide.TextItem,
    identifier: UInt64,
    parentIdentifier: UInt64
  ) throws -> TSPArchiveRecord {
    guard let stylesheetIdentifier = try documentStylesheetIdentifier() else {
      throw ArchiveSurgeryError.missingSlideRecord(identifier: 0)
    }
    let properties = characterStyleProperties(for: item)
    var style = TSWP_ParagraphStyleArchive()
    style.super.isVariation = true
    style.super.parent.identifier = parentIdentifier
    style.super.stylesheet.identifier = stylesheetIdentifier
    style.charProperties = properties.bag
    style.paraProperties = TSWP_ParagraphStylePropertiesArchive()
    style.overrideCount = properties.count
    var messageInfo = TSP_MessageInfo()
    messageInfo.type = Self.paragraphStyleArchiveType
    messageInfo.version = BuildRecordFactory.version
    messageInfo.objectReferences = [parentIdentifier]
    var info = TSP_ArchiveInfo()
    info.identifier = identifier
    info.messageInfos = [messageInfo]
    return TSPArchiveRecord(
      info: info,
      payloads: [try style.serializedBytes(partial: true)]
    )
  }

  /// The storage's current paragraph style (`tableParaStyle` entry 0), used
  /// as the fork's parent.
  internal func currentParagraphStyleIdentifier(
    ofStorage identifier: UInt64
  ) throws -> UInt64? {
    let catalog = SlideCatalog(members: members)
    guard
      let location = try catalog.locate(
        recordIdentifier: identifier,
        named: "TSWP.StorageArchive"
      )
    else {
      return nil
    }
    let storage = try TSWP_StorageArchive(
      serializedBytes: members[location.memberIndex]
        .records[location.recordIndex]
        .payloads[location.payloadIndex],
      partial: true
    )
    return storage.tableParaStyle.entries.first?.object.identifier
  }

  /// Character-style property bag for an authored text item, plus the number
  /// of overridden properties (`overrideCount` on the fork).
  private func characterStyleProperties(
    for item: AuthoredSlide.TextItem
  ) -> (bag: TSWP_CharacterStylePropertiesArchive, count: UInt32) {
    Self.characterStyleProperties(
      fontName: item.fontName,
      fontSize: item.fontSize,
      isBold: item.isBold,
      isItalic: item.isItalic,
      color: item.color
    )
  }
}
