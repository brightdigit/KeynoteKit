//
//  AuthoredSlide.TextItem+Run.swift
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

extension AuthoredSlide.TextItem {
  /// One styled span of a paragraph. Spans concatenate in order into the
  /// paragraph's text; style fields override the item-wide formatting for
  /// that span only.
  package struct Run: Equatable, Sendable {
    /// The span's string.
    package var text: String

    /// Authored font family; `nil` inherits the item / template style.
    package var fontName: String?

    /// Authored font size; `nil` inherits the item / template style.
    package var fontSize: Double?

    /// Authored bold; `nil` inherits the item / template style.
    package var isBold: Bool?

    /// Authored italic; `nil` inherits the item / template style.
    package var isItalic: Bool?

    /// Authored sRGB color; `nil` inherits the item / template style.
    package var color: TextColor?

    /// Whether any style field is set on this span.
    package var hasFormatting: Bool {
      fontName != nil || fontSize != nil || isBold != nil || isItalic != nil || color != nil
    }

    /// Creates a span.
    package init(
      text: String,
      fontName: String? = nil,
      fontSize: Double? = nil,
      isBold: Bool? = nil,
      isItalic: Bool? = nil,
      color: TextColor? = nil
    ) {
      self.text = text
      self.fontName = fontName
      self.fontSize = fontSize
      self.isBold = isBold
      self.isItalic = isItalic
      self.color = color
    }
  }
}
