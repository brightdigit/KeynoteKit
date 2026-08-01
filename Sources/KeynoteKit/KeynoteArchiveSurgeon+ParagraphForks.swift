//
//  KeynoteArchiveSurgeon+ParagraphForks.swift
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

extension KeynoteArchiveSurgeon {
  /// One paragraph's effective layout: its own fields merged over the
  /// item-wide alignment default.
  internal struct ParagraphFormat: Hashable {
    /// Effective alignment.
    internal var alignment: TextAlignment?

    /// Left indent in points.
    internal var leftIndent: Double?

    /// First-line indent in points.
    internal var firstLineIndent: Double?

    /// Right indent in points.
    internal var rightIndent: Double?
  }

  /// The forked paragraph styles for one text item: `tableParaStyle`
  /// entries (run-length collapsed over paragraphs) plus the minted fork
  /// records, all variations of the storage's original style.
  internal struct ParagraphStyleApplication {
    /// The storage's original paragraph style — every fork's parent.
    internal var parentIdentifier: UInt64

    /// One entry per format change, at the paragraph's UTF-16 start offset.
    internal var entries: [(characterIndex: UInt32, identifier: UInt64)]

    /// The minted fork records, one per distinct effective format.
    internal var forks: [MintedTextStyle]
  }

  /// Mints the paragraph-style forks carrying an item's formatting: one
  /// fork per distinct effective paragraph format, each holding the
  /// item-wide character properties (a `tableParaStyle` entry applies from
  /// its offset onward) plus that format's paragraph properties. Returns
  /// `nil` when nothing is set — the storage keeps the template's entry.
  internal mutating func mintedParagraphForks(
    for item: AuthoredSlide.TextItem,
    storageIdentifier: UInt64,
    nextIdentifier: inout UInt64,
    minted: inout MintedSlide
  ) throws -> ParagraphStyleApplication? {
    guard item.hasFormatting || item.hasParagraphFormatting,
      let parentIdentifier = try currentParagraphStyleIdentifier(ofStorage: storageIdentifier)
    else {
      return nil
    }
    var forkByFormat: [ParagraphFormat: UInt64] = [:]
    var forks: [MintedTextStyle] = []
    var identifiers: [UInt64] = []
    for paragraph in item.paragraphs {
      let format = effectiveFormat(of: paragraph, itemAlignment: item.textAlignment)
      if let existing = forkByFormat[format] {
        identifiers.append(existing)
        continue
      }
      let identifier = nextIdentifier
      nextIdentifier += 1
      let record = try paragraphStyleRecord(
        for: item,
        format: format,
        identifier: identifier,
        parentIdentifier: parentIdentifier
      )
      forks.append(
        MintedTextStyle(record: record, identifier: identifier, parentIdentifier: parentIdentifier)
      )
      forkByFormat[format] = identifier
      identifiers.append(identifier)
      minted.maximumIdentifier = max(minted.maximumIdentifier, identifier)
    }
    return ParagraphStyleApplication(
      parentIdentifier: parentIdentifier,
      entries: collapsedEntries(of: item, identifiers: identifiers),
      forks: forks
    )
  }

  /// A paragraph's format merged over the item-wide alignment.
  private func effectiveFormat(
    of paragraph: AuthoredSlide.TextItem.ParagraphItem,
    itemAlignment: TextAlignment?
  ) -> ParagraphFormat {
    ParagraphFormat(
      alignment: paragraph.alignment ?? itemAlignment,
      leftIndent: paragraph.leftIndent,
      firstLineIndent: paragraph.firstLineIndent,
      rightIndent: paragraph.rightIndent
    )
  }

  /// `tableParaStyle` entries at each paragraph's UTF-16 start offset in
  /// the joined text, with runs of adjacent identical forks collapsed into
  /// the first paragraph's entry.
  private func collapsedEntries(
    of item: AuthoredSlide.TextItem,
    identifiers: [UInt64]
  ) -> [(characterIndex: UInt32, identifier: UInt64)] {
    var entries: [(characterIndex: UInt32, identifier: UInt64)] = []
    var offset: UInt32 = 0
    for (index, paragraph) in item.paragraphs.enumerated() {
      if index > 0 {
        offset += 1  // the "\n" joining paragraphs into the storage text
      }
      if entries.last?.identifier != identifiers[index] {
        entries.append((characterIndex: offset, identifier: identifiers[index]))
      }
      offset += UInt32(paragraph.text.utf16.count)
    }
    return entries
  }
}
