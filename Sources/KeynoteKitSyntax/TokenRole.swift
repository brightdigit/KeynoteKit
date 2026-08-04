//
//  TokenRole.swift
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

/// The semantic category a source token falls into, and the unit a
/// ``CodeTheme`` assigns a color to.
///
/// Deliberately coarse. A finer taxonomy (distinguishing enum cases from
/// struct names, say) needs semantic analysis rather than a parse tree, and
/// would give a theme more knobs than a slide can usefully show at
/// presentation distance.
public enum TokenRole: String, CaseIterable, Sendable {
  /// Language keywords — `func`, `let`, `if`, `return`.
  case keyword

  /// Type names in type position.
  ///
  /// Distinguishing a type from a plain identifier needs the *parent* node,
  /// not the token: `Foo` is a type in `let x: Foo` and an identifier in
  /// `Foo()`. See ``SwiftHighlighter``.
  case type

  /// String and character literals, including interpolation delimiters.
  case string

  /// Numeric literals.
  case number

  /// Comments, which arrive as trivia rather than tokens.
  case comment

  /// Anything else — identifiers, operators, punctuation, whitespace.
  case plain
}
