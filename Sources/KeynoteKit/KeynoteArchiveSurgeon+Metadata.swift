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

extension TSP_ComponentDataReference {
  /// One data blob referenced `count` times by a single object.
  internal static func singleUse(
    dataIdentifier: UInt64,
    objectIdentifier: UInt64,
    count: UInt32 = 1
  ) -> TSP_ComponentDataReference {
    var dataReference = TSP_ComponentDataReference()
    dataReference.dataIdentifier = dataIdentifier
    var objectReference = TSP_ComponentDataReference.ObjectReference()
    objectReference.objectIdentifier = objectIdentifier
    objectReference.count = count
    dataReference.objectReferenceList = [objectReference]
    return dataReference
  }
}

extension KeynoteArchiveSurgeon {
  /// Merges one (object → data) usage into a component's data-reference
  /// list, extending the existing row for `dataIdentifier` when present.
  ///
  /// A record whose header declares a data reference that the owning
  /// component does not register fails TSP's integrity check and silently
  /// refuses to load.
  internal mutating func registerDataObjectReference(
    dataIdentifier: UInt64,
    objectIdentifier: UInt64,
    count: UInt32,
    componentStem: String
  ) throws {
    try withPackageMetadata { metadata in
      guard
        let componentIndex = metadata.components.firstIndex(where: {
          $0.preferredLocator == componentStem || $0.locator == componentStem
        })
      else {
        throw ArchiveSurgeryError.missingComponent(stem: componentStem)
      }
      var objectReference = TSP_ComponentDataReference.ObjectReference()
      objectReference.objectIdentifier = objectIdentifier
      objectReference.count = count
      var rows = metadata.components[componentIndex].dataReferences
      if let rowIndex = rows.firstIndex(where: { $0.dataIdentifier == dataIdentifier }) {
        rows[rowIndex].objectReferenceList.append(objectReference)
      } else {
        var row = TSP_ComponentDataReference()
        row.dataIdentifier = dataIdentifier
        row.objectReferenceList = [objectReference]
        rows.append(row)
      }
      metadata.components[componentIndex].dataReferences = rows
    }
  }

  /// Registers new `DataInfo` rows and slide-component data references.
  internal mutating func registerData(
    infos: [TSP_DataInfo],
    componentReferences: [TSP_ComponentDataReference],
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
      metadata.components[componentIndex].dataReferences.append(
        contentsOf: componentReferences
      )
    }
  }

  /// Registers cross-component external references on the slide's component.
  ///
  /// A slide object may reference an object owned by another component (e.g.
  /// an image pointing at a `DocumentStylesheet` media style) only when the
  /// slide component declares that edge — Keynote throws during layout when
  /// the declaration is missing.
  internal mutating func registerExternalReferences(
    _ references: [(ownerStem: String, objectIdentifier: UInt64)],
    slideIdentifier: UInt64
  ) throws {
    guard !references.isEmpty else {
      return
    }
    try withPackageMetadata { metadata in
      guard
        let componentIndex = metadata.components.firstIndex(where: {
          $0.identifier == slideIdentifier
        })
      else {
        throw ArchiveSurgeryError.missingSlideComponent(slideIdentifier: slideIdentifier)
      }
      for reference in references {
        guard
          let owner = metadata.components.first(where: {
            $0.preferredLocator == reference.ownerStem || $0.locator == reference.ownerStem
          })
        else {
          throw ArchiveSurgeryError.missingComponent(stem: reference.ownerStem)
        }
        let alreadyListed = metadata.components[componentIndex].externalReferences.contains {
          $0.componentIdentifier == owner.identifier
            && $0.objectIdentifier == reference.objectIdentifier
        }
        if alreadyListed { continue }
        var external = TSP_ComponentExternalReference()
        external.componentIdentifier = owner.identifier
        external.objectIdentifier = reference.objectIdentifier
        metadata.components[componentIndex].externalReferences.append(external)
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
