//
//  ParagraphsBuilder.swift
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

/// Collects ``Paragraph`` elements for a ``TextBox``. Each bare ``Text``
/// becomes its own single-span paragraph.
@resultBuilder
public enum ParagraphsBuilder {
  /// Collects the block's paragraphs.
  public static func buildBlock(_ paragraphs: [Paragraph]...) -> [Paragraph] {
    paragraphs.flatMap { $0 }
  }

  /// Lifts a paragraph into the block.
  public static func buildExpression(_ paragraph: Paragraph) -> [Paragraph] {
    [paragraph]
  }

  /// Lifts a bare span into its own paragraph.
  public static func buildExpression(_ span: Text) -> [Paragraph] {
    [Paragraph { span }]
  }

  /// Supports `if` without `else`.
  public static func buildOptional(_ paragraphs: [Paragraph]?) -> [Paragraph] {
    paragraphs ?? []
  }

  /// Supports `if` / `else` (first branch).
  public static func buildEither(first paragraphs: [Paragraph]) -> [Paragraph] {
    paragraphs
  }

  /// Supports `if` / `else` (second branch).
  public static func buildEither(second paragraphs: [Paragraph]) -> [Paragraph] {
    paragraphs
  }

  /// Supports `for` loops.
  public static func buildArray(_ paragraphs: [[Paragraph]]) -> [Paragraph] {
    paragraphs.flatMap { $0 }
  }
}
