//
//  Paragraph.swift
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

/// One paragraph of a ``TextBox``: one or more ``Text`` spans plus
/// per-paragraph alignment and indentation.
///
/// Each bare ``Text`` directly in a ``TextBox`` builder becomes its own
/// paragraph; multi-span paragraphs are written explicitly:
/// `Paragraph { Text("bold").bold(); Text(" plain") }`.
public struct Paragraph: Sendable {
  /// The paragraph's styled spans, concatenated in declaration order.
  internal var runs: [Text]

  /// Per-paragraph alignment; `nil` inherits the item-wide
  /// ``TextBox/textAlignment(_:)`` or the template style.
  internal var alignment: TextAlignment?

  /// Left indent in points; `nil` inherits.
  internal var leftIndent: Double?

  /// First-line indent in points; `nil` inherits.
  internal var firstLineIndent: Double?

  /// Right indent in points; `nil` inherits.
  internal var rightIndent: Double?

  /// Creates a single-span paragraph.
  public init(_ content: String) {
    self.runs = [Text(content)]
  }

  /// Creates a paragraph from styled spans, concatenated in declaration
  /// order.
  public init(@TextRunsBuilder _ runs: () -> [Text]) {
    self.runs = runs()
  }

  /// Sets the paragraph's indentation, in points. `firstLine` overrides the
  /// first line and defaults to `left` — the archive's first-line indent is
  /// absolute, so leaving it unset would keep single-line paragraphs at the
  /// margin. An unset `right` inherits.
  public func indent(
    _ left: Double,
    firstLine: Double? = nil,
    right: Double? = nil
  ) -> Paragraph {
    var paragraph = self
    paragraph.leftIndent = left
    paragraph.firstLineIndent = firstLine ?? left
    paragraph.rightIndent = right
    return paragraph
  }

  /// Sets the paragraph's alignment, overriding the item-wide default.
  public func alignment(_ alignment: TextAlignment) -> Paragraph {
    var paragraph = self
    paragraph.alignment = alignment
    return paragraph
  }
}
