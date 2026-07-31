//
//  KeynoteArchiveSurgeon+StylesheetRegistry.swift
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
  /// Identifier of the document `TSS.StylesheetArchive`, if present.
  internal func documentStylesheetIdentifier() throws -> UInt64? {
    let catalog = SlideCatalog(members: members)
    guard let location = try catalog.locateFirst(named: "TSS.StylesheetArchive") else {
      return nil
    }
    return members[location.memberIndex].records[location.recordIndex].info.identifier
  }

  /// Registers a forked style on the stylesheet: the `styles` list plus —
  /// when the style has a parent — the parent→children variation map Keynote
  /// maintains for style forks. Parentless minted styles (per-run character
  /// styles) register on the `styles` list only.
  internal mutating func registerStyleInDocumentStylesheet(
    _ styleIdentifier: UInt64,
    parentIdentifier: UInt64?
  ) throws {
    let catalog = SlideCatalog(members: members)
    guard let location = try catalog.locateFirst(named: "TSS.StylesheetArchive") else {
      throw ArchiveSurgeryError.missingSlideRecord(identifier: styleIdentifier)
    }
    var sheet = try TSS_StylesheetArchive(
      serializedBytes: members[location.memberIndex]
        .records[location.recordIndex]
        .payloads[location.payloadIndex],
      partial: true
    )
    var reference = TSP_Reference()
    reference.identifier = styleIdentifier
    if !sheet.styles.contains(where: { $0.identifier == styleIdentifier }) {
      sheet.styles.append(reference)
    }
    if let parentIdentifier {
      appendVariation(
        reference,
        underParent: parentIdentifier,
        to: &sheet.parentToChildrenStyleMap
      )
    }
    members[location.memberIndex].records[location.recordIndex]
      .payloads[location.payloadIndex] = try sheet.serializedBytes(partial: true)
  }

  /// Adds a fork to its parent's entry in the variation map.
  private func appendVariation(
    _ reference: TSP_Reference,
    underParent parentIdentifier: UInt64,
    to map: inout [TSS_StylesheetArchive.StyleChildrenEntry]
  ) {
    if let mapIndex = map.firstIndex(where: {
      $0.parent.identifier == parentIdentifier
    }) {
      if !map[mapIndex].children.contains(where: {
        $0.identifier == reference.identifier
      }) {
        map[mapIndex].children.append(reference)
      }
    } else {
      var entry = TSS_StylesheetArchive.StyleChildrenEntry()
      entry.parent.identifier = parentIdentifier
      entry.children = [reference]
      map.append(entry)
    }
  }
}
