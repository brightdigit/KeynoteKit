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
    minted: inout MintedSlide
  ) throws {
    let textItems = items.enumerated().compactMap { index, item -> (Int, AuthoredSlide.TextItem)? in
      if case .text(let text) = item {
        return (index, text)
      }
      return nil
    }
    let catalog = SlideCatalog(members: members)
    var styleRecords: [TSPArchiveRecord] = []
    var styleIdentifiers: [UInt64] = []
    for (index, item) in textItems {
      if let style = try applyTextItem(
        item,
        at: index,
        slideArchive: slideArchive,
        catalog: catalog,
        slideIndex: slideIndex,
        nextIdentifier: &nextIdentifier,
        minted: &minted
      ) {
        styleRecords.append(style.record)
        styleIdentifiers.append(style.identifier)
      }
    }
    if !styleRecords.isEmpty {
      try appendCharacterStylesToDocumentStylesheet(styleRecords)
      for styleIdentifier in styleIdentifiers {
        try registerStyleInDocumentStylesheet(styleIdentifier)
      }
    }
  }

  /// Appends minted character-style records to `DocumentStylesheet.iwa`.
  private mutating func appendCharacterStylesToDocumentStylesheet(
    _ records: [TSPArchiveRecord]
  ) throws {
    let catalog = SlideCatalog(members: members)
    guard let location = try catalog.locateFirst(named: "TSS.StylesheetArchive") else {
      throw ArchiveSurgeryError.missingSlideRecord(identifier: 0)
    }
    members[location.memberIndex].records.append(contentsOf: records)
  }

  /// Applies one text item; returns a minted character style when formatting is set.
  private mutating func applyTextItem(
    _ item: AuthoredSlide.TextItem,
    at index: Int,
    slideArchive: KN_SlideArchive,
    catalog: SlideCatalog,
    slideIndex: Int,
    nextIdentifier: inout UInt64,
    minted: inout MintedSlide
  ) throws -> (record: TSPArchiveRecord, identifier: UInt64)? {
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
    var characterStyleIdentifier: UInt64?
    var mintedStyle: (record: TSPArchiveRecord, identifier: UInt64)?
    if item.hasFormatting {
      let styleIdentifier = nextIdentifier
      nextIdentifier += 1
      let record = try characterStyleRecord(for: item, identifier: styleIdentifier)
      characterStyleIdentifier = styleIdentifier
      minted.maximumIdentifier = max(minted.maximumIdentifier, styleIdentifier)
      mintedStyle = (record, styleIdentifier)
    }
    let placeholder = try KN_PlaceholderArchive(
      serializedBytes: members[placeholderLocation.memberIndex]
        .records[placeholderLocation.recordIndex]
        .payloads[placeholderLocation.payloadIndex],
      partial: true
    )
    try applyText(
      item.text,
      characterStyleIdentifier: characterStyleIdentifier,
      toStorage: placeholder.super.ownedStorage.identifier
    )
    return mintedStyle
  }

  /// Writes authored position and optional size onto a placeholder.
  private mutating func writePlaceholderGeometry(
    _ item: AuthoredSlide.TextItem,
    at placeholderLocation: SlideCatalog.Location
  ) throws {
    var placeholder = try KN_PlaceholderArchive(
      serializedBytes: members[placeholderLocation.memberIndex]
        .records[placeholderLocation.recordIndex]
        .payloads[placeholderLocation.payloadIndex],
      partial: true
    )
    placeholder.super.super.super.geometry.position.x = Float(item.x)
    placeholder.super.super.super.geometry.position.y = Float(item.y)
    if let width = item.width {
      placeholder.super.super.super.geometry.size.width = Float(width)
    }
    if let height = item.height {
      placeholder.super.super.super.geometry.size.height = Float(height)
    }
    members[placeholderLocation.memberIndex].records[placeholderLocation.recordIndex]
      .payloads[placeholderLocation.payloadIndex] = try placeholder.serializedBytes(partial: true)
  }
}
