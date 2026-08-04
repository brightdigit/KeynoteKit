//
//  Paragraph+Lowering.swift
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

extension Paragraph {
  /// Lowers this paragraph into the writer's representation.
  ///
  /// Lives on `Paragraph` rather than `Deck` so ``TextBox/lowered()`` can
  /// call it: the drawable now lowers itself, so its parts must too.
  internal func lowered() -> AuthoredSlide.TextItem.ParagraphItem {
    AuthoredSlide.TextItem.ParagraphItem(
      runs: runs.map { run in
        AuthoredSlide.TextItem.Run(
          text: run.content,
          fontName: run.fontName,
          fontSize: run.fontSize,
          isBold: run.isBold,
          isItalic: run.isItalic,
          color: run.color
        )
      },
      alignment: alignment,
      leftIndent: leftIndent,
      firstLineIndent: firstLineIndent,
      rightIndent: rightIndent
    )
  }
}
