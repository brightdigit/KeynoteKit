//
//  AuthoredSlide+TextItem.swift
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

extension AuthoredSlide {
  /// A text item's content and position, applied to the slide's drawables
  /// in order. Empty means "leave the base slide's items untouched" (the
  /// golden differential path).
  package struct TextItem: Equatable, Sendable {
    /// One paragraph: spans plus per-paragraph alignment and indentation.
    package struct ParagraphItem: Equatable, Sendable {
      /// The paragraph's spans, concatenated in order.
      package var runs: [Run]

      /// Per-paragraph alignment; `nil` inherits the item-wide default.
      package var alignment: TextAlignment?

      /// Left indent in points; `nil` inherits.
      package var leftIndent: Double?

      /// First-line indent in points; `nil` inherits.
      package var firstLineIndent: Double?

      /// Right indent in points; `nil` inherits.
      package var rightIndent: Double?

      /// The paragraph's string: its spans joined.
      package var text: String {
        runs.map(\.text).joined()
      }

      /// Whether any per-paragraph layout field is set.
      package var hasParagraphFormatting: Bool {
        alignment != nil || leftIndent != nil || firstLineIndent != nil || rightIndent != nil
      }

      /// Creates a paragraph.
      package init(
        runs: [Run],
        alignment: TextAlignment? = nil,
        leftIndent: Double? = nil,
        firstLineIndent: Double? = nil,
        rightIndent: Double? = nil
      ) {
        self.runs = runs
        self.alignment = alignment
        self.leftIndent = leftIndent
        self.firstLineIndent = firstLineIndent
        self.rightIndent = rightIndent
      }
    }

    /// The item's paragraphs, joined by `"\n"` into the storage text.
    package var paragraphs: [ParagraphItem]

    /// The string content: paragraphs joined by newlines.
    package var text: String {
      paragraphs.map(\.text).joined(separator: "\n")
    }

    /// The x position.
    package var x: Double

    /// The y position.
    package var y: Double

    /// Authored width; `nil` leaves the template size.
    package var width: Double?

    /// Authored height; `nil` leaves the template size.
    package var height: Double?

    /// Authored font family; `nil` leaves the template style.
    package var fontName: String?

    /// Authored font size; `nil` leaves the template style.
    package var fontSize: Double?

    /// Authored bold; `nil` leaves the template style.
    package var isBold: Bool?

    /// Authored italic; `nil` leaves the template style.
    package var isItalic: Bool?

    /// Authored sRGB color; `nil` leaves the template style.
    package var color: TextColor?

    /// Authored list style; `nil` means plain (the theme's None style).
    package var listStyle: TextListStyle?

    /// Authored rotation, clockwise-positive; `nil` leaves the box unrotated.
    package var rotation: Angle?

    /// Item-wide paragraph alignment; per-paragraph alignment overrides it.
    package var textAlignment: TextAlignment?

    /// Vertical alignment within the box; `nil` leaves the template's.
    package var verticalAlignment: VerticalTextAlignment?

    /// Column count; `nil` leaves the template's single column.
    package var columnCount: Int?

    /// Column gutter in points; `nil` inherits the template's gutter.
    package var columnGap: Double?

    /// Whether any item-wide formatting field is set.
    package var hasFormatting: Bool {
      fontName != nil || fontSize != nil || isBold != nil || isItalic != nil || color != nil
    }

    /// Whether any span carries its own style overrides.
    package var hasRunFormatting: Bool {
      paragraphs.contains { $0.runs.contains(where: \.hasFormatting) }
    }

    /// Whether the item-wide alignment or any paragraph's layout is set.
    package var hasParagraphFormatting: Bool {
      textAlignment != nil || paragraphs.contains(where: \.hasParagraphFormatting)
    }

    /// Creates a text item.
    package init(
      x: Double,
      y: Double,
      width: Double? = nil,
      height: Double? = nil,
      fontName: String? = nil,
      fontSize: Double? = nil,
      isBold: Bool? = nil,
      isItalic: Bool? = nil,
      color: TextColor? = nil,
      listStyle: TextListStyle? = nil,
      rotation: Angle? = nil,
      textAlignment: TextAlignment? = nil,
      verticalAlignment: VerticalTextAlignment? = nil,
      columnCount: Int? = nil,
      columnGap: Double? = nil,
      paragraphs: [ParagraphItem]
    ) {
      self.x = x
      self.y = y
      self.width = width
      self.height = height
      self.fontName = fontName
      self.fontSize = fontSize
      self.isBold = isBold
      self.isItalic = isItalic
      self.color = color
      self.listStyle = listStyle
      self.rotation = rotation
      self.textAlignment = textAlignment
      self.verticalAlignment = verticalAlignment
      self.columnCount = columnCount
      self.columnGap = columnGap
      self.paragraphs = paragraphs
    }
  }
}
