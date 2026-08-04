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

/// The result builder collecting a slide's layout elements — drawables,
/// stacks, spacers, and padded wrappers.
///
/// Collects ``SlideLayout`` rather than `[SlideDrawable]` so a stack can
/// nest. The tree resolves to absolutely-positioned drawables at build time
/// (see ``LayoutNode/resolve(in:origin:)``), so the surgeon still receives
/// the same flat, absolutely-positioned list it always has.
@resultBuilder
public enum SlideItemsBuilder {
  /// Lifts a text item into the builder's element list.
  public static func buildExpression(_ text: TextBox) -> [any SlideLayout] {
    [text]
  }

  /// Lifts an image item into the builder's element list.
  public static func buildExpression(_ image: Image) -> [any SlideLayout] {
    [image]
  }

  /// Lifts any layout element — stack, spacer, or padded wrapper.
  public static func buildExpression(_ layout: any SlideLayout) -> [any SlideLayout] {
    [layout]
  }

  /// Combines the block's elements.
  public static func buildBlock(_ items: [any SlideLayout]...) -> [any SlideLayout] {
    items.flatMap { $0 }
  }

  /// Supports `for` loops.
  public static func buildArray(_ items: [[any SlideLayout]]) -> [any SlideLayout] {
    items.flatMap { $0 }
  }

  /// Supports `if` without `else`.
  public static func buildOptional(_ items: [any SlideLayout]?) -> [any SlideLayout] {
    items ?? []
  }

  /// Supports the `if` branch of `if`/`else`.
  public static func buildEither(first items: [any SlideLayout]) -> [any SlideLayout] {
    items
  }

  /// Supports the `else` branch of `if`/`else`.
  public static func buildEither(second items: [any SlideLayout]) -> [any SlideLayout] {
    items
  }
}
