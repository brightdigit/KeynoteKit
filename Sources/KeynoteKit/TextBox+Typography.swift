//
//  TextBox+Typography.swift
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
  /// Sets the font family and optional size.
  public func font(_ name: String, size: Double? = nil) -> TextBox {
    var text = self
    text.fontName = name
    if let size {
      text.fontSize = size
    }
    return text
  }

  /// Sets the font size in points.
  public func fontSize(_ size: Double) -> TextBox {
    var text = self
    text.fontSize = size
    return text
  }

  /// Marks the text bold.
  public func bold(_ isBold: Bool = true) -> TextBox {
    var text = self
    text.isBold = isBold
    return text
  }

  /// Marks the text italic.
  public func italic(_ isItalic: Bool = true) -> TextBox {
    var text = self
    text.isItalic = isItalic
    return text
  }

  /// Sets the text color.
  public func foregroundColor(_ color: Color) -> TextBox {
    var text = self
    text.color = color
    return text
  }
}
