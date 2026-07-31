//
//  KeynoteArchiveSurgeon+CharacterRuns.swift
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
  /// One minted per-run character style plus its span's start offset.
  internal struct MintedRunStyle {
    /// The minted `TSWP.CharacterStyleArchive` record.
    internal var record: TSPArchiveRecord

    /// The record identifier.
    internal var identifier: UInt64

    /// UTF-16 offset of the span's first character in the item's text.
    internal var characterIndex: UInt32
  }

  /// Registry type for `TSWP.CharacterStyleArchive`.
  private static let characterStyleArchiveType: UInt32 = 2_021

  /// Mints one `TSWP.CharacterStyleArchive` per span when any span carries
  /// its own overrides. Plain spans mint an override-free style so their
  /// `tableCharStyle` entry resets the preceding span's overrides — a
  /// zero-identifier reference is never written, because Keynote resolves it
  /// to nil and silently fails the component load.
  internal func characterRunStyles(
    for item: AuthoredSlide.TextItem,
    nextIdentifier: inout UInt64
  ) throws -> [MintedRunStyle] {
    guard item.hasRunFormatting else {
      return []
    }
    guard let stylesheetIdentifier = try documentStylesheetIdentifier() else {
      throw ArchiveSurgeryError.missingSlideRecord(identifier: 0)
    }
    var styles: [MintedRunStyle] = []
    var offset: UInt32 = 0
    for run in item.runs {
      let identifier = nextIdentifier
      nextIdentifier += 1
      styles.append(
        MintedRunStyle(
          record: try characterStyleRecord(
            for: run,
            identifier: identifier,
            stylesheetIdentifier: stylesheetIdentifier
          ),
          identifier: identifier,
          characterIndex: offset
        )
      )
      offset += UInt32(run.text.utf16.count)
    }
    return styles
  }

  /// Mints the character style carrying one span's overrides. Mirrors the
  /// paragraph-style fork's shape: `stylesheet` super, character properties
  /// (color with `tsdFill`), `overrideCount`, and the stylesheet on the
  /// record header's references.
  private func characterStyleRecord(
    for run: AuthoredSlide.TextItem.Run,
    identifier: UInt64,
    stylesheetIdentifier: UInt64
  ) throws -> TSPArchiveRecord {
    let properties = Self.characterStyleProperties(
      fontName: run.fontName,
      fontSize: run.fontSize,
      isBold: run.isBold,
      isItalic: run.isItalic,
      color: run.color
    )
    var style = TSWP_CharacterStyleArchive()
    style.super.stylesheet.identifier = stylesheetIdentifier
    style.charProperties = properties.bag
    style.overrideCount = properties.count
    var messageInfo = TSP_MessageInfo()
    messageInfo.type = Self.characterStyleArchiveType
    messageInfo.version = BuildRecordFactory.version
    messageInfo.objectReferences = [stylesheetIdentifier]
    var info = TSP_ArchiveInfo()
    info.identifier = identifier
    info.messageInfos = [messageInfo]
    return TSPArchiveRecord(
      info: info,
      payloads: [try style.serializedBytes(partial: true)]
    )
  }
}
