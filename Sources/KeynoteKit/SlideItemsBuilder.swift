//
//  SlideItemsBuilder.swift
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

/// The result builder collecting a slide's ``TextBox`` and ``Image`` items.
@resultBuilder
public enum SlideItemsBuilder {
  /// Lifts a text item into the builder's drawable list.
  public static func buildExpression(_ text: TextBox) -> [SlideDrawable] {
    [.text(text)]
  }

  /// Lifts an image item into the builder's drawable list.
  public static func buildExpression(_ image: Image) -> [SlideDrawable] {
    [.image(image)]
  }

  /// Combines the block's items.
  public static func buildBlock(_ items: [SlideDrawable]...) -> [SlideDrawable] {
    items.flatMap { $0 }
  }

  /// Supports `for` loops.
  public static func buildArray(_ items: [[SlideDrawable]]) -> [SlideDrawable] {
    items.flatMap { $0 }
  }
}
