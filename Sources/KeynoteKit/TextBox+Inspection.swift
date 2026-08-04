//
//  TextBox+Inspection.swift
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
  /// The number of paragraphs the box holds.
  ///
  /// Test support: multi-paragraph structure is what #81 got wrong, and it
  /// is invisible from the public surface otherwise. `internal` rather than
  /// `package` — the repo's `package` declarations are whole-type lowering
  /// DTOs shared across targets, not per-property test accessors, so tests
  /// reach these through `@testable import` instead. `internal` rather than
  /// `package` — the repo's `package` declarations are whole-type lowering
  /// DTOs shared across targets, not per-property test accessors, so tests
  /// reach these through `@testable import` instead.
  internal var paragraphCount: Int { paragraphs.count }

  /// Each paragraph's plain text, in order.
  internal var paragraphTexts: [String] {
    paragraphs.map { $0.runs.map(\.content).joined() }
  }

  /// The box's text with paragraphs rejoined by newlines.
  internal var plainText: String { content }

  /// The item-level font family, when set.
  internal var itemFontName: String? { fontName }

  /// The item-level font size, when set.
  internal var itemFontSize: Double? { fontSize }

  /// The number of styled spans in the paragraph at `index`.
  internal func styledRunCount(inParagraph index: Int) -> Int {
    guard paragraphs.indices.contains(index) else {
      return 0
    }
    return paragraphs[index].runs.count
  }
}
