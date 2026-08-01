//
//  KeynoteArchiveSurgeon+ListStyle.swift
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

/// Theme list-style `styleIdentifier` suffixes shipped by the template.
///
/// Themes name their list styles `text-<n>-liststyle-<Kind>`; the numeric
/// prefix varies per theme, so styles resolve by suffix, never by record id.
internal enum ThemeListStyleSuffix {
  /// The plain (no label) list style.
  internal static let none = "liststyle-None"

  /// The "•" bullet list style.
  internal static let bullet = "liststyle-Bullet"

  /// The decimal-numbered list style.
  internal static let numbered = "liststyle-Numbered"
}

extension KeynoteArchiveSurgeon {
  /// The record identifier of the theme list style whose `styleIdentifier`
  /// ends in `suffix`, scanning `TSWP.ListStyleArchive` records in archive
  /// order.
  internal func themeListStyleIdentifier(suffix: String) throws -> UInt64 {
    for member in members {
      for record in member.records {
        guard
          let payloadIndex = record.resolvedTypes.firstIndex(where: {
            TSPRegistryMapping.messageName(for: $0) == "TSWP.ListStyleArchive"
          })
        else {
          continue
        }
        let style = try TSWP_ListStyleArchive(
          serializedBytes: record.payloads[payloadIndex],
          partial: true
        )
        if style.super.styleIdentifier.hasSuffix(suffix) {
          return record.info.identifier
        }
      }
    }
    throw ArchiveSurgeryError.missingThemeListStyle(suffix: suffix)
  }
}
