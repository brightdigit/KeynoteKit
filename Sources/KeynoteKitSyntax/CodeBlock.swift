//
//  CodeBlock.swift
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

/// Swift source rendered as a syntax-highlighted ``TextBox``.
///
/// ```swift
/// CodeBlock("""
///   func render() {
///     try deck.write(to: url)
///   }
///   """)
///   .position(x: 120, y: 220)
///   .frame(width: 1_400, height: 500)
/// ```
///
/// ## Why this emits per-span runs
///
/// Item-level `.font()` styles a whole box uniformly, which cannot express
/// per-token colour. So each token becomes its own ``Text`` span, and each
/// source line becomes its own ``Paragraph``.
///
/// That is the shape #81 fixed. Before it, only the first paragraph of a
/// multi-paragraph box got styled and interior lines silently rendered at
/// the template default — invisible to every structural check. Code blocks
/// are inherently multi-line, so this type would have shipped broken; the
/// tests here use three-plus-line samples for exactly that reason.
public struct CodeBlock {
  /// The source to highlight.
  private let source: String

  /// The theme colouring it.
  private let theme: CodeTheme

  /// The highlighted text box.
  ///
  /// Call this to place the block on a slide; every ``TextBox`` modifier is
  /// available on the result.
  public var textBox: TextBox {
    let lines = Self.lines(of: SwiftHighlighter.spans(of: source))
    return TextBox {
      for line in lines {
        Paragraph {
          for span in line {
            styled(span)
          }
        }
      }
    }
    .font(theme.fontName, size: theme.fontSize)
  }

  /// Creates a highlighted code block.
  ///
  /// - Parameters:
  ///   - source: Swift source. Parsed, never executed.
  ///   - theme: Colours and font. Defaults to ``CodeTheme/midnight``.
  public init(_ source: String, theme: CodeTheme = .midnight) {
    self.source = source
    self.theme = theme
  }

  /// Splits spans at newlines so each source line becomes one paragraph.
  ///
  /// A span can straddle a line break — a run of whitespace trivia commonly
  /// does — so the split happens on text, not on span boundaries.
  private static func lines(of spans: [SwiftHighlighter.Span]) -> [[SwiftHighlighter.Span]] {
    var lines: [[SwiftHighlighter.Span]] = [[]]
    for span in spans {
      let parts = span.text.components(separatedBy: "\n")
      for (index, part) in parts.enumerated() {
        if index > 0 {
          lines.append([])
        }
        guard !part.isEmpty else {
          continue
        }
        lines[lines.count - 1].append(
          SwiftHighlighter.Span(text: part, role: span.role)
        )
      }
    }
    // A trailing newline leaves an empty last line; drop it rather than
    // emit a blank paragraph the author did not write.
    if lines.count > 1, lines[lines.count - 1].isEmpty {
      lines.removeLast()
    }
    return lines
  }

  /// One span as a styled ``Text``.
  private func styled(_ span: SwiftHighlighter.Span) -> Text {
    let text = Text(span.text).font(theme.fontName, size: theme.fontSize)
    guard let color = theme.colors[span.role] else {
      return text
    }
    return text.foregroundColor(color)
  }
}
