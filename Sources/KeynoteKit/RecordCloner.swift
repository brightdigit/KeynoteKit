//
//  RecordCloner.swift
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

/// Clones archive records with fresh identifiers, rewriting the internal
/// references between cloned records and leaving external references
/// (styles, template slides, stylesheets) shared.
///
/// The rewritten fields are exactly the internal-reference inventory
/// measured on the bundled blank template (PLAN decision log, #22): the
/// slide's placeholder/note/guide references, the placeholder drawable
/// chain, a storage's attachment table, and a note's contained storage.
package enum RecordCloner {
  /// Clones `records`, giving each an identifier from `map` and remapping
  /// every internal reference; identifiers absent from `map` are external
  /// and stay shared.
  package static func clone(
    _ records: [TSPArchiveRecord],
    map: [UInt64: UInt64]
  ) throws -> [TSPArchiveRecord] {
    try records.map { record in
      var cloned = record
      cloned.info.identifier = map[record.info.identifier] ?? record.info.identifier
      for index in cloned.info.messageInfos.indices {
        cloned.info.messageInfos[index].objectReferences =
          cloned.info.messageInfos[index].objectReferences.map { map[$0] ?? $0 }
      }
      cloned.payloads = try zip(record.resolvedTypes, record.payloads).map { type, payload in
        try rewritten(payload, name: TSPRegistryMapping.messageName(for: type), map: map)
      }
      return cloned
    }
  }

  /// Remaps `reference` when it points at a cloned record.
  package static func remap(_ reference: inout TSP_Reference, map: [UInt64: UInt64]) {
    if let replacement = map[reference.identifier] {
      reference.identifier = replacement
    }
  }

  /// Rewrites one payload's internal references, by message type.
  private static func rewritten(
    _ payload: [UInt8],
    name: String?,
    map: [UInt64: UInt64]
  ) throws -> [UInt8] {
    switch name {
    case "KN.SlideArchive":
      try rewrittenSlide(payload, map: map)
    case "KN.PlaceholderArchive":
      try rewrittenPlaceholder(payload, map: map)
    case "TSWP.StorageArchive":
      try rewrittenStorage(payload, map: map)
    case "KN.NoteArchive":
      try rewrittenNote(payload, map: map)
    case "KN.SlideNodeArchive":
      try rewrittenNode(payload, map: map)
    default:
      payload
    }
  }

  private static func rewrittenSlide(_ payload: [UInt8], map: [UInt64: UInt64]) throws -> [UInt8] {
    var slide = try KN_SlideArchive(serializedBytes: payload, partial: true)
    remapSlideAnchors(&slide, map: map)
    remapSlideLists(&slide, map: map)
    return try slide.serializedBytes(partial: true)
  }

  /// Remaps the slide's singular references.
  ///
  /// Touching an absent optional field through its accessor materializes an
  /// EMPTY reference (identifier 0) — Keynote resolves it to nil and
  /// silently refuses to load the slide. Only remap fields that exist.
  private static func remapSlideAnchors(_ slide: inout KN_SlideArchive, map: [UInt64: UInt64]) {
    if slide.hasTitlePlaceholder { remap(&slide.titlePlaceholder, map: map) }
    if slide.hasBodyPlaceholder { remap(&slide.bodyPlaceholder, map: map) }
    if slide.hasSlideNumberPlaceholder { remap(&slide.slideNumberPlaceholder, map: map) }
    if slide.hasObjectPlaceholder { remap(&slide.objectPlaceholder, map: map) }
    if slide.hasNote { remap(&slide.note, map: map) }
    if slide.hasUserDefinedGuideStorage { remap(&slide.userDefinedGuideStorage, map: map) }
  }

  /// Remaps the slide's repeated references.
  private static func remapSlideLists(_ slide: inout KN_SlideArchive, map: [UInt64: UInt64]) {
    for index in slide.drawablesZOrder.indices {
      remap(&slide.drawablesZOrder[index], map: map)
    }
    for index in slide.builds.indices {
      remap(&slide.builds[index], map: map)
    }
    for index in slide.buildChunks.indices {
      remap(&slide.buildChunks[index], map: map)
    }
  }

  private static func rewrittenPlaceholder(
    _ payload: [UInt8],
    map: [UInt64: UInt64]
  ) throws -> [UInt8] {
    var placeholder = try KN_PlaceholderArchive(serializedBytes: payload, partial: true)
    if placeholder.super.hasDeprecatedStorage {
      remap(&placeholder.super.deprecatedStorage, map: map)
    }
    if placeholder.super.hasOwnedStorage {
      remap(&placeholder.super.ownedStorage, map: map)
    }
    if placeholder.super.super.super.hasCaption {
      remap(&placeholder.super.super.super.caption, map: map)
    }
    if placeholder.super.super.super.hasTitle {
      remap(&placeholder.super.super.super.title, map: map)
    }
    if placeholder.super.super.super.hasParent {
      remap(&placeholder.super.super.super.parent, map: map)
    }
    return try placeholder.serializedBytes(partial: true)
  }

  private static func rewrittenStorage(
    _ payload: [UInt8],
    map: [UInt64: UInt64]
  ) throws -> [UInt8] {
    var storage = try TSWP_StorageArchive(serializedBytes: payload, partial: true)
    for index in storage.tableAttachment.entries.indices {
      remap(&storage.tableAttachment.entries[index].object, map: map)
    }
    return try storage.serializedBytes(partial: true)
  }

  private static func rewrittenNote(_ payload: [UInt8], map: [UInt64: UInt64]) throws -> [UInt8] {
    var note = try KN_NoteArchive(serializedBytes: payload, partial: true)
    if note.hasContainedStorage {
      remap(&note.containedStorage, map: map)
    }
    return try note.serializedBytes(partial: true)
  }

  private static func rewrittenNode(_ payload: [UInt8], map: [UInt64: UInt64]) throws -> [UInt8] {
    var node = try KN_SlideNodeArchive(serializedBytes: payload, partial: true)
    if node.hasSlide {
      remap(&node.slide, map: map)
    }
    return try node.serializedBytes(partial: true)
  }
}
