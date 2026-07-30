//
//  KeynoteArchiveSurgeon+SlideCloning.swift
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

package import IWAFraming
package import KeynoteKitProtobuf

extension KeynoteArchiveSurgeon {
  /// Clones the last slide in presentation order: its whole member as a new
  /// `Index/Slide-<id>.iwa` entry, its slide node in `Document.iwa`, the
  /// show's slide-tree reference, and a fresh metadata component.
  internal mutating func cloneLastSlide(
    in bundle: inout KeyBundle,
    nextIdentifier: inout UInt64
  ) throws {
    let catalog = SlideCatalog(members: members)
    guard let template = try catalog.orderedSlides().last else {
      throw ArchiveSurgeryError.missingShowArchive
    }
    let templateMember = members[template.memberIndex]
    var map: [UInt64: UInt64] = [:]
    for record in templateMember.records {
      map[record.info.identifier] = nextIdentifier
      nextIdentifier += 1
    }
    let nodeIdentifier = nextIdentifier
    map[template.nodeIdentifier] = nodeIdentifier
    nextIdentifier += 1

    let newSlideIdentifier = map[template.slideIdentifier] ?? 0
    let clonedRecords = try RecordCloner.clone(templateMember.records, map: map)
    let newPath = "Index/Slide-\(newSlideIdentifier).iwa"
    members.insert(
      (path: newPath, records: clonedRecords),
      at: template.memberIndex + 1
    )
    var entries = bundle.entries
    if let anchor = entries.firstIndex(where: { $0.path == templateMember.path }) {
      entries.insert(KeyBundleEntry(path: newPath, body: []), at: anchor + 1)
    } else {
      entries.append(KeyBundleEntry(path: newPath, body: []))
    }
    bundle.entries = entries

    try cloneSlideNode(
      template: template,
      map: map,
      nodeIdentifier: nodeIdentifier
    )
    try appendComponent(
      like: template.slideIdentifier,
      newSlideIdentifier: newSlideIdentifier
    )
  }

  /// Clones the template's slide node and appends it to the slide tree.
  private mutating func cloneSlideNode(
    template: SlideCatalog.Slide,
    map: [UInt64: UInt64],
    nodeIdentifier: UInt64
  ) throws {
    let catalog = SlideCatalog(members: members)
    guard
      let nodeLocation = try catalog.locate(
        recordIdentifier: template.nodeIdentifier,
        named: "KN.SlideNodeArchive"
      ),
      let showLocation = try catalog.locateFirst(named: "KN.ShowArchive")
    else {
      throw ArchiveSurgeryError.missingSlideRecord(identifier: template.nodeIdentifier)
    }
    let nodeRecord = members[nodeLocation.memberIndex].records[nodeLocation.recordIndex]
    let cloned = try RecordCloner.clone([nodeRecord], map: map)
    members[nodeLocation.memberIndex].records.insert(
      contentsOf: cloned,
      at: nodeLocation.recordIndex + 1
    )
    var show = try KN_ShowArchive(
      serializedBytes: members[showLocation.memberIndex]
        .records[showLocation.recordIndex].payloads[showLocation.payloadIndex],
      partial: true
    )
    var reference = TSP_Reference()
    reference.identifier = nodeIdentifier
    show.slideTree.slides.append(reference)
    members[showLocation.memberIndex].records[showLocation.recordIndex]
      .payloads[showLocation.payloadIndex] = try show.serializedBytes(partial: true)
    var info = members[showLocation.memberIndex].records[showLocation.recordIndex].info
    info.messageInfos[0].objectReferences.append(nodeIdentifier)
    members[showLocation.memberIndex].records[showLocation.recordIndex].info = info
  }

  /// Registers a fresh component for a cloned slide, modeled on the
  /// template slide's component.
  private mutating func appendComponent(
    like templateSlideIdentifier: UInt64,
    newSlideIdentifier: UInt64
  ) throws {
    try withPackageMetadata { metadata in
      guard
        let templateComponent = metadata.components.first(where: {
          $0.identifier == templateSlideIdentifier
        })
      else {
        throw ArchiveSurgeryError.missingSlideComponent(
          slideIdentifier: templateSlideIdentifier
        )
      }
      var component = templateComponent
      component.identifier = newSlideIdentifier
      if component.hasLocator {
        component.locator = "Slide-\(newSlideIdentifier)"
      }
      component.objectUuidMapEntries = []
      metadata.components.append(component)
      if let docIndex = metadata.components.firstIndex(where: {
        $0.preferredLocator == "Document" || $0.identifier == 1
      }) {
        var ref = TSP_ComponentExternalReference()
        ref.componentIdentifier = newSlideIdentifier
        metadata.components[docIndex].externalReferences.append(ref)
      }
    }
  }
}
