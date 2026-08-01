//
//  KeynoteArchiveSurgeon+DrawableItems.swift
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
  /// One style minted for a formatted text item: a paragraph-style fork
  /// (item-wide formatting, with a parent), a per-run character style
  /// (span overrides, parentless), or a list-style variation.
  internal struct MintedTextStyle {
    internal var record: TSPArchiveRecord
    internal var identifier: UInt64
    internal var parentIdentifier: UInt64?
  }

  /// Writes each drawable's content into `drawablesZOrder` slots.
  ///
  /// Images are fully authored during ``expandDrawables``; text placeholders
  /// still need string / position / style application here.
  internal mutating func applyDrawableItems(
    _ items: [AuthoredSlide.DrawableItem],
    to slideArchive: inout KN_SlideArchive,
    at location: SlideCatalog.Slide,
    slideIndex: Int,
    nextIdentifier: inout UInt64,
    minted: inout MintedSlide,
    using generator: inout some RandomNumberGenerator
  ) throws {
    let textItems = items.enumerated().compactMap { index, item -> (Int, AuthoredSlide.TextItem)? in
      if case .text(let text) = item {
        return (index, text)
      }
      return nil
    }
    let catalog = SlideCatalog(members: members)
    var styles: [MintedTextStyle] = []
    for (index, item) in textItems {
      styles.append(
        contentsOf: try applyTextItem(
          item,
          at: index,
          slideArchive: slideArchive,
          catalog: catalog,
          slideIndex: slideIndex,
          nextIdentifier: &nextIdentifier,
          minted: &minted
        )
      )
    }
    if !styles.isEmpty {
      let ownerStem = try appendCharacterStylesToDocumentStylesheet(styles.map(\.record))
      for style in styles {
        try registerStyleInDocumentStylesheet(
          style.identifier,
          parentIdentifier: style.parentIdentifier
        )
      }
      try registerCharacterStyleMetadata(
        styles.map(\.identifier),
        ownerStem: ownerStem,
        at: location,
        minted: &minted,
        using: &generator
      )
    }
  }

  /// Applies one text item; returns the styles minted for it — a
  /// paragraph-style fork when item-wide formatting is set, plus one
  /// character style per span when any span carries its own overrides.
  private mutating func applyTextItem(
    _ item: AuthoredSlide.TextItem,
    at index: Int,
    slideArchive: KN_SlideArchive,
    catalog: SlideCatalog,
    slideIndex: Int,
    nextIdentifier: inout UInt64,
    minted: inout MintedSlide
  ) throws -> [MintedTextStyle] {
    guard slideArchive.drawablesZOrder.indices.contains(index) else {
      throw ArchiveSurgeryError.targetOutOfRange(slideIndex: slideIndex, targetIndex: index)
    }
    let drawableIdentifier = slideArchive.drawablesZOrder[index].identifier
    guard
      let placeholderLocation = try catalog.locate(
        recordIdentifier: drawableIdentifier,
        named: "KN.PlaceholderArchive"
      )
    else {
      throw ArchiveSurgeryError.missingSlideRecord(identifier: drawableIdentifier)
    }
    try writePlaceholderGeometry(item, at: placeholderLocation)
    let storageIdentifier = try ownedStorageIdentifier(at: placeholderLocation)
    let paragraphStyles = try mintedParagraphForks(
      for: item,
      storageIdentifier: storageIdentifier,
      nextIdentifier: &nextIdentifier,
      minted: &minted
    )
    let runStyles = try characterRunStyles(for: item, nextIdentifier: &nextIdentifier)
    if let last = runStyles.last {
      minted.maximumIdentifier = max(minted.maximumIdentifier, last.identifier)
    }
    let listStyle = try resolvedListStyle(
      for: item.listStyle,
      nextIdentifier: &nextIdentifier,
      minted: &minted
    )
    try applyText(
      item.text,
      paragraphStyles: paragraphStyles,
      characterRuns: runStyles.map {
        CharacterRunEntry(characterIndex: $0.characterIndex, styleIdentifier: $0.identifier)
      },
      listStyleIdentifier: listStyle.identifier,
      toStorage: storageIdentifier
    )
    return collectedStyles(
      paragraphForks: paragraphStyles?.forks ?? [],
      runStyles: runStyles,
      listMint: listStyle.mintedStyle
    )
  }
}
