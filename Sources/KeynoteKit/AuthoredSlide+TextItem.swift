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
    /// One styled span of the item's text. Spans concatenate in order into
    /// ``TextItem/text``; style fields override the item-wide formatting for
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

    /// The string content.
    package var text: String

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

    /// Styled spans; empty means the whole item is one span styled by the
    /// item-wide fields above.
    package var runs: [Run]

    /// Whether any item-wide formatting field is set.
    package var hasFormatting: Bool {
      fontName != nil || fontSize != nil || isBold != nil || isItalic != nil || color != nil
    }

    /// Whether any span carries its own style overrides.
    package var hasRunFormatting: Bool {
      runs.contains(where: \.hasFormatting)
    }

    /// Creates a text item.
    package init(
      text: String,
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
      runs: [Run] = []
    ) {
      self.text = text
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
      self.runs = runs
    }
  }
}
