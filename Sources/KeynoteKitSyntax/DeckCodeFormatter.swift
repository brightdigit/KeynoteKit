//
//  DeckCodeFormatter.swift
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

internal import KeynoteKit

/// An in-place code formatting engine that scans raw text content or Keynote text blocks,
/// detects Swift code, and transforms it into syntax-highlighted ``CodeBlock`` elements.
public struct DeckCodeFormatter: Sendable {
  /// The color theme used for styling code.
  public var theme: CodeTheme

  /// Creates a formatter with a given theme.
  ///
  /// - Parameter theme: Color and typography theme. Defaults to ``CodeTheme/midnight``.
  public init(theme: CodeTheme = .midnight) {
    self.theme = theme
  }

  /// Determines whether a text string contains markdown code fences (e.g. ` ```swift `).
  ///
  /// - Parameter text: The text string to inspect.
  /// - Returns: `true` if the text begins or contains code fence markers.
  public func isCodeFence(_ text: String) -> Bool {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.hasPrefix("```swift") || trimmed.hasPrefix("```")
  }

  /// Extracts clean code content by stripping markdown code fences if present.
  ///
  /// - Parameter text: Raw text string with optional code fences.
  /// - Returns: Clean source code ready for syntax highlighting.
  public func stripCodeFence(_ text: String) -> String {
    guard isCodeFence(text) else {
      return text
    }
    var lines = text.components(separatedBy: "\n")
    if let first = lines.first, first.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
      lines.removeFirst()
    }
    if let last = lines.last, last.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
      lines.removeLast()
    }
    return lines.joined(separator: "\n")
  }

  /// Formats raw Swift code text into a highlighted ``CodeBlock``.
  ///
  /// - Parameter rawText: Unformatted Swift code text or markdown fenced code.
  /// - Returns: A syntax-highlighted ``CodeBlock``.
  public func formatCodeText(_ rawText: String) -> CodeBlock {
    let cleanSource = stripCodeFence(rawText)
    return CodeBlock(cleanSource, theme: theme)
  }
}
