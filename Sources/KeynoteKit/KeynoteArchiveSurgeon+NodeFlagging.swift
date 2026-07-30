//
//  KeynoteArchiveSurgeon+NodeFlagging.swift
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
  /// Sets the slide node's build-count flags (`hasBuilds` stays untouched).
  internal mutating func flagSlideNode(
    at location: SlideCatalog.Slide,
    buildCount: Int,
    dirtyPaths: inout Set<String>
  ) throws {
    guard
      let nodeLocation = try SlideCatalog(members: members)
        .locate(recordIdentifier: location.nodeIdentifier, named: "KN.SlideNodeArchive")
    else {
      throw ArchiveSurgeryError.missingSlideRecord(identifier: location.nodeIdentifier)
    }
    var node = try KN_SlideNodeArchive(
      serializedBytes: members[nodeLocation.memberIndex]
        .records[nodeLocation.recordIndex].payloads[nodeLocation.payloadIndex],
      partial: true
    )
    node.buildEventCount = UInt32(buildCount)
    node.buildEventCountCacheVersion = 2
    node.hasExplicitBuilds_p = true
    node.hasExplicitBuildsCacheVersion_p = 2
    members[nodeLocation.memberIndex].records[nodeLocation.recordIndex]
      .payloads[nodeLocation.payloadIndex] = try node.serializedBytes(partial: true)
    dirtyPaths.insert(members[nodeLocation.memberIndex].path)
  }

  /// Sets `hasTransition = true` on the slide node.
  internal mutating func flagSlideNodeTransition(
    at location: SlideCatalog.Slide,
    dirtyPaths: inout Set<String>
  ) throws {
    guard
      let nodeLocation = try SlideCatalog(members: members)
        .locate(recordIdentifier: location.nodeIdentifier, named: "KN.SlideNodeArchive")
    else {
      throw ArchiveSurgeryError.missingSlideRecord(identifier: location.nodeIdentifier)
    }
    var node = try KN_SlideNodeArchive(
      serializedBytes: members[nodeLocation.memberIndex]
        .records[nodeLocation.recordIndex].payloads[nodeLocation.payloadIndex],
      partial: true
    )
    node.hasTransition_p = true
    members[nodeLocation.memberIndex].records[nodeLocation.recordIndex]
      .payloads[nodeLocation.payloadIndex] = try node.serializedBytes(partial: true)
    dirtyPaths.insert(members[nodeLocation.memberIndex].path)
  }
}
