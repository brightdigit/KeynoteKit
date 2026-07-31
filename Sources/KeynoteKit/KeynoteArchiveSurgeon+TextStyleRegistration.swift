//
//  KeynoteArchiveSurgeon+TextStyleRegistration.swift
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
  /// Registers the cross-component bookkeeping a minted text style needs
  /// to *render*: uuid-map entries in both the stylesheet and slide
  /// components, and a slide-component external reference — Keynote silently
  /// drops the style (text renders plain) when any edge is missing.
  internal mutating func registerCharacterStyleMetadata(
    _ styleIdentifiers: [UInt64],
    ownerStem: String,
    at location: SlideCatalog.Slide,
    minted: inout MintedSlide,
    using generator: inout some RandomNumberGenerator
  ) throws {
    var entries: [TSP_ObjectUUIDMapEntry] = []
    for styleIdentifier in styleIdentifiers {
      var uuid = TSP_UUID()
      uuid.lower = UInt64.random(in: .min ... .max, using: &generator)
      uuid.upper = UInt64.random(in: .min ... .max, using: &generator)
      var entry = TSP_ObjectUUIDMapEntry()
      entry.identifier = styleIdentifier
      entry.uuid = uuid
      entries.append(entry)
      minted.uuidEntries.append(entry)
    }
    try registerUUIDEntries(entries, componentStem: ownerStem)
    try registerExternalReferences(
      styleIdentifiers.map { (ownerStem: ownerStem, objectIdentifier: $0) },
      slideIdentifier: location.slideIdentifier
    )
  }

  /// Appends minted text-style records to `DocumentStylesheet.iwa`;
  /// returns the stylesheet member's locator stem.
  internal mutating func appendCharacterStylesToDocumentStylesheet(
    _ records: [TSPArchiveRecord]
  ) throws -> String {
    let catalog = SlideCatalog(members: members)
    guard let location = try catalog.locateFirst(named: "TSS.StylesheetArchive") else {
      throw ArchiveSurgeryError.missingSlideRecord(identifier: 0)
    }
    members[location.memberIndex].records.append(contentsOf: records)
    return Self.locatorStem(of: members[location.memberIndex].path)
  }
}
