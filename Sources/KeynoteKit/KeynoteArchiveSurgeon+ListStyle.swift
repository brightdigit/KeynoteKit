//
//  KeynoteArchiveSurgeon+ListStyle.swift
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

/// Theme list-style `styleIdentifier` suffixes shipped by the template.
///
/// Themes name their list styles `text-<n>-liststyle-<Kind>`; the numeric
/// prefix varies per theme, so styles resolve by suffix, never by record id.
internal enum ThemeListStyleSuffix {
  /// The plain (no label) list style.
  internal static let none = "liststyle-None"

  /// The "•" bullet list style.
  internal static let bullet = "liststyle-Bullet"

  /// The decimal-numbered list style.
  internal static let numbered = "liststyle-Numbered"
}

extension KeynoteArchiveSurgeon {
  /// Registry type for `TSWP.ListStyleArchive`.
  private static let listStyleArchiveType: UInt32 = 2_023

  /// The theme ancestor a style variation forks from.
  private static func themeSuffix(for style: TextListStyle) -> String {
    switch style.label {
    case .themeNone:
      ThemeListStyleSuffix.none
    case .themeBullet, .bulletCharacter:
      ThemeListStyleSuffix.bullet
    case .numbered:
      ThemeListStyleSuffix.numbered
    }
  }

  /// Resolves an item's list style to the record the storage should
  /// reference: theme styles repoint at the shipped record; custom labels
  /// and indents mint a variation off the matching theme parent so all list
  /// levels' geometry inherit.
  internal mutating func resolvedListStyle(
    for style: TextListStyle?,
    nextIdentifier: inout UInt64,
    minted: inout MintedSlide
  ) throws -> (identifier: UInt64, mintedStyle: MintedTextStyle?) {
    let style = style ?? .none
    let parentIdentifier = try themeListStyleIdentifier(suffix: Self.themeSuffix(for: style))
    guard style.requiresMint else {
      return (parentIdentifier, nil)
    }
    let identifier = nextIdentifier
    nextIdentifier += 1
    let record = try listStyleVariationRecord(
      style,
      parentIdentifier: parentIdentifier,
      identifier: identifier
    )
    minted.maximumIdentifier = max(minted.maximumIdentifier, identifier)
    return (
      identifier,
      MintedTextStyle(
        record: record,
        identifier: identifier,
        parentIdentifier: parentIdentifier
      )
    )
  }

  /// Mints a `TSWP.ListStyleArchive` variation of the theme parent. Each
  /// override is mirrored across every list level: the archive's per-level
  /// arrays are parallel, so a partial array would misalign labels against
  /// the inherited indents and geometries.
  private func listStyleVariationRecord(
    _ style: TextListStyle,
    parentIdentifier: UInt64,
    identifier: UInt64
  ) throws -> TSPArchiveRecord {
    guard let stylesheetIdentifier = try documentStylesheetIdentifier() else {
      throw ArchiveSurgeryError.missingSlideRecord(identifier: parentIdentifier)
    }
    let parent = try listStyleArchive(withIdentifier: parentIdentifier)
    let levels = max(parent.labelTypes.count, 1)
    var archive = TSWP_ListStyleArchive()
    archive.super.isVariation = true
    archive.super.parent.identifier = parentIdentifier
    archive.super.stylesheet.identifier = stylesheetIdentifier
    var overrides: UInt32 = 0
    switch style.label {
    case .themeNone, .themeBullet:
      break
    case .bulletCharacter(let character):
      archive.labelTypes = Array(repeating: .kString, count: levels)
      archive.strings = Array(repeating: character, count: levels)
      overrides += 2
    case .numbered(let format):
      archive.labelTypes = Array(repeating: .kNumber, count: levels)
      archive.numberTypes = Array(repeating: format.archiveNumberType, count: levels)
      overrides += 2
    }
    if let indent = style.indentPoints {
      archive.indents = Array(repeating: Float(indent), count: levels)
      overrides += 1
    }
    archive.overrideCount = overrides
    var messageInfo = TSP_MessageInfo()
    messageInfo.type = Self.listStyleArchiveType
    messageInfo.version = BuildRecordFactory.version
    messageInfo.objectReferences = [parentIdentifier, stylesheetIdentifier]
    var info = TSP_ArchiveInfo()
    info.identifier = identifier
    info.messageInfos = [messageInfo]
    return TSPArchiveRecord(
      info: info,
      payloads: [try archive.serializedBytes(partial: true)]
    )
  }

  /// Decodes the list style record with `identifier`.
  private func listStyleArchive(
    withIdentifier identifier: UInt64
  ) throws -> TSWP_ListStyleArchive {
    let catalog = SlideCatalog(members: members)
    guard
      let location = try catalog.locate(
        recordIdentifier: identifier,
        named: "TSWP.ListStyleArchive"
      )
    else {
      throw ArchiveSurgeryError.missingSlideRecord(identifier: identifier)
    }
    return try TSWP_ListStyleArchive(
      serializedBytes: members[location.memberIndex]
        .records[location.recordIndex]
        .payloads[location.payloadIndex],
      partial: true
    )
  }

  /// The record identifier of the theme list style whose `styleIdentifier`
  /// ends in `suffix`, scanning `TSWP.ListStyleArchive` records in archive
  /// order.
  internal func themeListStyleIdentifier(suffix: String) throws -> UInt64 {
    for member in members {
      for record in member.records {
        guard
          let payloadIndex = record.resolvedTypes.firstIndex(where: {
            TSPRegistryMapping.messageName(for: $0) == "TSWP.ListStyleArchive"
          })
        else {
          continue
        }
        let style = try TSWP_ListStyleArchive(
          serializedBytes: record.payloads[payloadIndex],
          partial: true
        )
        if style.super.styleIdentifier.hasSuffix(suffix) {
          return record.info.identifier
        }
      }
    }
    throw ArchiveSurgeryError.missingThemeListStyle(suffix: suffix)
  }
}

extension NumberFormat {
  /// The archive number type for the format, with a trailing period
  /// (`1.`, `I.`, `a.` …) matching the theme's Numbered style.
  internal var archiveNumberType: TSWP_ListStyleArchive.NumberType {
    switch self {
    case .decimal: .kNumericDecimal
    case .romanUpper: .kRomanUpperDecimal
    case .romanLower: .kRomanLowerDecimal
    case .alphaUpper: .kAlphaUpperDecimal
    case .alphaLower: .kAlphaLowerDecimal
    }
  }
}
