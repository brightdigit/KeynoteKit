//
//  TextRun.swift
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

/// One styled span inside a ``Text`` item. Runs concatenate in declaration
/// order into the item's string; each run's style fields override the item's
/// (paragraph-wide) formatting for that span only.
public struct TextRun: Sendable {
  /// The run's string content.
  internal var content: String

  /// Authored font family; `nil` inherits the item / template style.
  internal var fontName: String?

  /// Authored font size in points; `nil` inherits the item / template style.
  internal var fontSize: Double?

  /// Authored bold; `nil` inherits the item / template style.
  internal var isBold: Bool?

  /// Authored italic; `nil` inherits the item / template style.
  internal var isItalic: Bool?

  /// Authored text color; `nil` inherits the item / template style.
  internal var color: TextColor?

  /// Creates a run.
  ///
  /// - Parameter content: The span's string.
  public init(_ content: String) {
    self.content = content
  }

  /// Sets the font family and optional size.
  public func font(_ name: String, size: Double? = nil) -> TextRun {
    var run = self
    run.fontName = name
    if let size {
      run.fontSize = size
    }
    return run
  }

  /// Sets the font size in points.
  public func fontSize(_ size: Double) -> TextRun {
    var run = self
    run.fontSize = size
    return run
  }

  /// Marks the run bold.
  public func bold(_ isBold: Bool = true) -> TextRun {
    var run = self
    run.isBold = isBold
    return run
  }

  /// Marks the run italic.
  public func italic(_ isItalic: Bool = true) -> TextRun {
    var run = self
    run.isItalic = isItalic
    return run
  }

  /// Sets the run's text color.
  public func foregroundColor(_ color: TextColor) -> TextRun {
    var run = self
    run.color = color
    return run
  }
}
