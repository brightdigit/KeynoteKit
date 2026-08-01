//
//  TextBox+Layout.swift
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

extension TextBox {
  /// Sets how paragraphs are labeled (bullet, number, or nothing).
  /// Unset means plain — authored text boxes never inherit the theme bullet.
  public func listStyle(_ style: TextListStyle) -> TextBox {
    var text = self
    text.listStyle = style
    return text
  }

  /// Rotates the box about its center. Positive angles rotate clockwise on
  /// screen, matching SwiftUI.
  public func rotationEffect(_ angle: Angle) -> TextBox {
    var text = self
    text.rotation = angle
    return text
  }

  /// Sets the item-wide paragraph alignment; ``Paragraph/alignment(_:)``
  /// overrides it per paragraph.
  public func textAlignment(_ alignment: TextAlignment) -> TextBox {
    var text = self
    text.textAlignment = alignment
    return text
  }

  /// Sets the vertical alignment of the text within the box.
  public func verticalAlignment(_ alignment: VerticalTextAlignment) -> TextBox {
    var text = self
    text.verticalAlignment = alignment
    return text
  }

  /// Lays the text out in equal columns. The gutter is in points; `nil`
  /// inherits the template's gutter.
  public func columns(_ count: Int, gap: Double? = nil) -> TextBox {
    var text = self
    text.columnCount = count
    text.columnGap = gap
    return text
  }
}
