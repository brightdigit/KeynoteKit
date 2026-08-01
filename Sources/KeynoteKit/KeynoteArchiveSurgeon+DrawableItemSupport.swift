//
//  KeynoteArchiveSurgeon+DrawableItemSupport.swift
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
  /// Flattens an item's minted styles: the paragraph fork, per-run
  /// character styles, and the list-style variation, when present.
  internal func collectedStyles(
    paragraphFork: MintedTextStyle?,
    runStyles: [MintedRunStyle],
    listMint: MintedTextStyle?
  ) -> [MintedTextStyle] {
    var styles = paragraphFork.map { [$0] } ?? []
    styles.append(
      contentsOf: runStyles.map {
        MintedTextStyle(record: $0.record, identifier: $0.identifier, parentIdentifier: nil)
      }
    )
    if let listMint {
      styles.append(listMint)
    }
    return styles
  }

  /// The owned-storage identifier of the placeholder record at `location`.
  internal func ownedStorageIdentifier(
    at location: SlideCatalog.Location
  ) throws -> UInt64 {
    let placeholder = try KN_PlaceholderArchive(
      serializedBytes: members[location.memberIndex]
        .records[location.recordIndex]
        .payloads[location.payloadIndex],
      partial: true
    )
    return placeholder.super.ownedStorage.identifier
  }

  /// Writes authored position and optional size onto a placeholder.
  internal mutating func writePlaceholderGeometry(
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
