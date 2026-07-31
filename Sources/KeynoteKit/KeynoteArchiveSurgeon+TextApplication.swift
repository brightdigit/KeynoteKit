//
//  KeynoteArchiveSurgeon+TextApplication.swift
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
  /// One `tableCharStyle` entry: a minted character style applied from a
  /// UTF-16 character index to the next entry's index.
  internal struct CharacterRunEntry {
    /// UTF-16 offset of the span's first character in the storage's text.
    internal var characterIndex: UInt32

    /// The minted `TSWP.CharacterStyleArchive` record identifier.
    internal var styleIdentifier: UInt64
  }

  /// Writes `text` into a placeholder's owned storage; when a forked
  /// paragraph style is supplied, swaps the storage's `tableParaStyle` entry
  /// and the record header reference from the parent style to the fork.
  /// Character runs, when supplied, become the storage's `tableCharStyle`
  /// object-attribute entries, each added to the record header's references —
  /// an unlisted cross-record reference resolves to nil at load and the run
  /// silently renders plain.
  internal mutating func applyText(
    _ text: String,
    paragraphStyle: (identifier: UInt64, parent: UInt64)?,
    characterRuns: [CharacterRunEntry] = [],
    toStorage identifier: UInt64
  ) throws {
    let catalog = SlideCatalog(members: members)
    guard
      let location = try catalog.locate(
        recordIdentifier: identifier,
        named: "TSWP.StorageArchive"
      )
    else {
      throw ArchiveSurgeryError.missingSlideRecord(identifier: identifier)
    }
    var storage = try TSWP_StorageArchive(
      serializedBytes: members[location.memberIndex]
        .records[location.recordIndex]
        .payloads[location.payloadIndex],
      partial: true
    )
    storage.text = [text]
    if let paragraphStyle {
      if storage.tableParaStyle.entries.isEmpty {
        var entry = TSWP_ObjectAttributeTable.ObjectAttribute()
        entry.characterIndex = 0
        entry.object.identifier = paragraphStyle.identifier
        storage.tableParaStyle.entries = [entry]
      } else {
        storage.tableParaStyle.entries[0].object.identifier = paragraphStyle.identifier
      }
      replaceRecordHeaderReference(
        paragraphStyle.parent,
        with: paragraphStyle.identifier,
        at: location
      )
    }
    if !characterRuns.isEmpty {
      storage.tableCharStyle.entries = characterRuns.map { run in
        var entry = TSWP_ObjectAttributeTable.ObjectAttribute()
        entry.characterIndex = run.characterIndex
        entry.object.identifier = run.styleIdentifier
        return entry
      }
      for run in characterRuns {
        appendRecordHeaderReference(run.styleIdentifier, at: location)
      }
    }
    members[location.memberIndex].records[location.recordIndex]
      .payloads[location.payloadIndex] = try storage.serializedBytes(partial: true)
  }

  /// Appends `new` to a record header's object references when absent.
  private mutating func appendRecordHeaderReference(
    _ new: UInt64,
    at location: SlideCatalog.Location
  ) {
    replaceRecordHeaderReference(new, with: new, at: location)
  }

  /// Swaps `old` for `new` on a record header's object references — an
  /// unlisted cross-record reference resolves to nil at load and the style
  /// silently fails to apply.
  private mutating func replaceRecordHeaderReference(
    _ old: UInt64,
    with new: UInt64,
    at location: SlideCatalog.Location
  ) {
    guard !members[location.memberIndex].records[location.recordIndex].info.messageInfos.isEmpty
    else {
      return
    }
    var references = members[location.memberIndex].records[location.recordIndex]
      .info.messageInfos[0].objectReferences
    guard !references.contains(new) else {
      return
    }
    if let index = references.firstIndex(of: old) {
      references[index] = new
    } else {
      references.append(new)
    }
    members[location.memberIndex].records[location.recordIndex]
      .info.messageInfos[0].objectReferences = references
  }
}
