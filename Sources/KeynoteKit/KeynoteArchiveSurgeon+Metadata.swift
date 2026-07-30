//
//  KeynoteArchiveSurgeon+Metadata.swift
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

  /// Registers new `DataInfo` rows and slide-component data references.
  internal mutating func registerData(
    infos: [TSP_DataInfo],
    componentReferences: [(dataIdentifier: UInt64, objectIdentifier: UInt64)],
    slideIdentifier: UInt64
  ) throws {
    try withPackageMetadata { metadata in
      metadata.datas.append(contentsOf: infos)
      guard
        let componentIndex = metadata.components.firstIndex(where: {
          $0.identifier == slideIdentifier
        })
      else {
        throw ArchiveSurgeryError.missingSlideComponent(slideIdentifier: slideIdentifier)
      }
      for reference in componentReferences {
        var dataReference = TSP_ComponentDataReference()
        dataReference.dataIdentifier = reference.dataIdentifier
        var objectReference = TSP_ComponentDataReference.ObjectReference()
        objectReference.objectIdentifier = reference.objectIdentifier
        objectReference.count = 1
        dataReference.objectReferenceList = [objectReference]
        metadata.components[componentIndex].dataReferences.append(dataReference)
      }
    }
  }

  /// Raises `lastObjectIdentifier` to `value` when it sits below it.
  internal mutating func bumpLastObjectIdentifier(to value: UInt64) throws {
    try withPackageMetadata { metadata in
      if metadata.hasLastObjectIdentifier, metadata.lastObjectIdentifier < value {
        metadata.lastObjectIdentifier = value
      }
    }
  }

  /// Decodes, mutates, and re-serializes the single `TSP.PackageMetadata`.
  internal mutating func withPackageMetadata(
    _ mutate: (inout TSP_PackageMetadata) throws -> Void
  ) throws {
    guard
      let location = try SlideCatalog(members: members)
        .locateFirst(named: "TSP.PackageMetadata")
    else {
      throw ArchiveSurgeryError.missingSlideComponent(slideIdentifier: 0)
    }
    var metadata = try TSP_PackageMetadata(
      serializedBytes: members[location.memberIndex]
        .records[location.recordIndex]
        .payloads[location.payloadIndex],
      partial: true
    )
    try mutate(&metadata)
    members[location.memberIndex].records[location.recordIndex]
      .payloads[location.payloadIndex] = try metadata.serializedBytes(partial: true)
    metadataPathHint = members[location.memberIndex].path
  }
}
