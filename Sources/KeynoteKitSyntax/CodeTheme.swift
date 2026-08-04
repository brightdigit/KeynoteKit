//
//  CodeTheme.swift
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

public import KeynoteKit

/// A mapping from ``TokenRole`` to color, plus the font a code block uses.
///
/// The font family is a **property, not a constant**, because which
/// monospaced families actually render is an empirical question — see
/// `research/findings/monospace_probe.md`. `Menlo` is the verified default.
public struct CodeTheme: Sendable {
  /// A dark theme: light text on the ``TextBox/background(_:)`` panel the
  /// demo deck uses for code.
  public static let midnight = CodeTheme(
    fontName: "Menlo",
    fontSize: 32,
    colors: [
      .keyword: Color(red: 0.78, green: 0.45, blue: 0.87),
      .type: Color(red: 0.36, green: 0.78, blue: 0.85),
      .string: Color(red: 0.90, green: 0.55, blue: 0.44),
      .number: Color(red: 0.84, green: 0.73, blue: 0.49),
      .comment: Color(red: 0.45, green: 0.51, blue: 0.55),
      .plain: Color(red: 0.92, green: 0.94, blue: 0.96),
    ]
  )

  /// The background that pairs with ``midnight``.
  public static let midnightBackground = Color(red: 0.11, green: 0.13, blue: 0.17)

  /// The monospaced family code is set in.
  ///
  /// Render-verified: `Menlo` resolves in Keynote 15.3 and is genuinely
  /// monospaced. `Courier New` and `Monaco` also work; `SF Mono` was not
  /// separately confirmed.
  public var fontName: String

  /// Point size for code text.
  public var fontSize: Double

  /// Color per role. Roles absent from the map render unstyled.
  public var colors: [TokenRole: Color]

  /// Creates a theme.
  public init(fontName: String = "Menlo", fontSize: Double = 32, colors: [TokenRole: Color]) {
    self.fontName = fontName
    self.fontSize = fontSize
    self.colors = colors
  }
}
