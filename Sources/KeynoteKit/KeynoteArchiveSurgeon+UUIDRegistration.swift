//
//  KeynoteArchiveSurgeon+UUIDRegistration.swift
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
  /// Appends uuid-map entries to the slide's component.
  internal mutating func registerUUIDEntries(
    _ entries: [TSP_ObjectUUIDMapEntry],
    slideIdentifier: UInt64
  ) throws {
    try withPackageMetadata { metadata in
      guard
        let componentIndex = metadata.components.firstIndex(where: {
          $0.identifier == slideIdentifier
        })
      else {
        throw ArchiveSurgeryError.missingSlideComponent(slideIdentifier: slideIdentifier)
      }
      let locator = metadata.components[componentIndex].locator
      guard locator.isEmpty || locator == "Slide-\(slideIdentifier)" else {
        throw ArchiveSurgeryError.unexpectedComponentLocator(locator)
      }
      metadata.components[componentIndex].objectUuidMapEntries.append(contentsOf: entries)
    }
  }

  /// Registers a fresh-uuid map entry for every record in the slide's member
  /// whose identifier is not in `existing`.
  ///
  /// Every record added to a slide member needs a fresh-uuid
  /// `objectUuidMapEntries` row in that slide's component — a missing entry
  /// loads the component blank or crashes Keynote with an NSSet-nil
  /// exception.
  internal mutating func registerFreshRecordUUIDs(
    notIn existing: Set<UInt64>,
    at location: SlideCatalog.Slide,
    using generator: inout some RandomNumberGenerator
  ) throws {
    var entries: [TSP_ObjectUUIDMapEntry] = []
    for record in members[location.memberIndex].records
    where !existing.contains(record.info.identifier) {
      var entry = TSP_ObjectUUIDMapEntry()
      entry.identifier = record.info.identifier
      entry.uuid.lower = UInt64.random(in: .min ... .max, using: &generator)
      entry.uuid.upper = UInt64.random(in: .min ... .max, using: &generator)
      entries.append(entry)
    }
    guard !entries.isEmpty else {
      return
    }
    try registerUUIDEntries(entries, slideIdentifier: location.slideIdentifier)
  }

  /// Appends uuid-map entries to the component whose locator stem matches
  /// `componentStem` (e.g. `DocumentStylesheet`).
  internal mutating func registerUUIDEntries(
    _ entries: [TSP_ObjectUUIDMapEntry],
    componentStem: String
  ) throws {
    guard !entries.isEmpty else {
      return
    }
    try withPackageMetadata { metadata in
      guard
        let componentIndex = metadata.components.firstIndex(where: {
          $0.preferredLocator == componentStem || $0.locator == componentStem
        })
      else {
        throw ArchiveSurgeryError.missingComponent(stem: componentStem)
      }
      metadata.components[componentIndex].objectUuidMapEntries.append(contentsOf: entries)
    }
  }
}
