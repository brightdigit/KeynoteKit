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
  /// Registry type for `TSWP.CharacterStyleArchive`.
  private static let characterStyleArchiveType: UInt32 = 2_021

  /// Mints a per-item `TSWP.CharacterStyleArchive` so formatting does not
  /// mutate the shared Body paragraph style in the document stylesheet.
  internal func characterStyleRecord(
    for item: AuthoredSlide.TextItem,
    identifier: UInt64
  ) throws -> TSPArchiveRecord {
    var properties = characterStyleProperties(for: item)
    var style = TSWP_CharacterStyleArchive()
    style.charProperties = properties
    style.overrideCount = 1
    var messageInfo = TSP_MessageInfo()
    messageInfo.type = Self.characterStyleArchiveType
    messageInfo.version = BuildRecordFactory.version
    var info = TSP_ArchiveInfo()
    info.identifier = identifier
    info.messageInfos = [messageInfo]
    return TSPArchiveRecord(
      info: info,
      payloads: [try style.serializedBytes(partial: true)]
    )
  }

  /// Character-style property bag for an authored text item.
  private func characterStyleProperties(
    for item: AuthoredSlide.TextItem
  ) -> TSWP_CharacterStylePropertiesArchive {
    var properties = TSWP_CharacterStylePropertiesArchive()
    if let isBold = item.isBold { properties.bold = isBold }
    if let isItalic = item.isItalic { properties.italic = isItalic }
    if let fontSize = item.fontSize { properties.fontSize = Float(fontSize) }
    if let fontName = item.fontName {
      properties.fontName = fontName
      properties.fontNameNull = false
    }
    if let color = item.color {
      var tspColor = TSP_Color()
      tspColor.model = .rgb
      tspColor.r = Float(color.red)
      tspColor.g = Float(color.green)
      tspColor.b = Float(color.blue)
      tspColor.a = Float(color.alpha)
      tspColor.rgbspace = .srgb
      properties.fontColor = tspColor
      properties.fontColorNull = false
    }
    return properties
  }

  /// Writes `text` into a placeholder's owned storage, optionally attaching
  /// a character-style run for the whole string.
  internal mutating func applyText(
    _ text: String,
    characterStyleIdentifier: UInt64?,
    toStorage identifier: UInt64
  ) throws {
    let catalog = SlideCatalog(members: members)
    guard
      let location = try catalog.locate(
        recordIdentifier: identifier,
        named: "TSWP.StorageArchive"
      )
    else {
      throw ArchiveSurgeryError.missingSlideRecord(identifier: identifier)
    }
    var storage = try TSWP_StorageArchive(
      serializedBytes: members[location.memberIndex]
        .records[location.recordIndex]
        .payloads[location.payloadIndex],
      partial: true
    )
    storage.text = [text]
    if let characterStyleIdentifier {
      var entry = TSWP_ObjectAttributeTable.ObjectAttribute()
      entry.characterIndex = 0
      entry.object.identifier = characterStyleIdentifier
      var table = TSWP_ObjectAttributeTable()
      table.entries = [entry]
      storage.tableCharStyle = table
    }
    members[location.memberIndex].records[location.recordIndex]
      .payloads[location.payloadIndex] = try storage.serializedBytes(partial: true)
  }
}
