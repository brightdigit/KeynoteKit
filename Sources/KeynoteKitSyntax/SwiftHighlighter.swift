//
//  SwiftHighlighter.swift
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

internal import SwiftParser
internal import SwiftSyntax

/// Splits Swift source into ``TokenRole``-tagged spans.
///
/// Walks the parse tree rather than lexing, because two of the roles cannot
/// be decided from a token alone:
///
/// - **Types.** `Foo` is a type in `let x: Foo` and a plain identifier in
///   `Foo()`. Only the parent node distinguishes them, so the walker checks
///   whether an identifier sits inside a type syntax node.
/// - **Comments.** They are not tokens at all — they arrive as leading or
///   trailing *trivia* attached to the next real token.
///
/// Spans come out in source order and concatenate back to the exact input,
/// which the round-trip test asserts. That property matters: a highlighter
/// that silently drops a character would corrupt the code on a slide.
internal enum SwiftHighlighter {
  /// One contiguous run of source sharing a role.
  internal struct Span: Equatable, Sendable {
    /// The source text.
    internal var text: String

    /// The role that text plays.
    internal var role: TokenRole
  }

  /// Tags `source` into spans, in source order.
  internal static func spans(of source: String) -> [Span] {
    let tree = Parser.parse(source: source)
    var spans: [Span] = []
    for token in tree.tokens(viewMode: .sourceAccurate) {
      append(trivia: token.leadingTrivia, to: &spans)
      let role = self.role(of: token)
      appendText(token.text, role: role, to: &spans)
      append(trivia: token.trailingTrivia, to: &spans)
    }
    return spans
  }

  /// The role a token plays, using its parent for context.
  private static func role(of token: TokenSyntax) -> TokenRole {
    switch token.tokenKind {
    case .stringSegment, .stringQuote, .multilineStringQuote,
      .rawStringPoundDelimiter, .singleQuote:
      return .string

    case .integerLiteral, .floatLiteral:
      return .number

    case .identifier:
      // `Foo` is a type in `let x: Foo`, an identifier in `Foo()`. The
      // token is identical; only the parent tells them apart.
      return token.parent?.is(IdentifierTypeSyntax.self) == true ? .type : .plain

    case .keyword:
      return .keyword

    default:
      return .plain
    }
  }

  /// Appends trivia, tagging comments and passing whitespace through.
  private static func append(trivia: Trivia, to spans: inout [Span]) {
    for piece in trivia {
      switch piece {
      case .lineComment(let text), .blockComment(let text),
        .docLineComment(let text), .docBlockComment(let text):
        appendText(text, role: .comment, to: &spans)

      default:
        var rendered = ""
        piece.write(to: &rendered)
        appendText(rendered, role: .plain, to: &spans)
      }
    }
  }

  /// Appends text, merging into the previous span when the role matches.
  ///
  /// Merging keeps the span count near the number of *visible* colour
  /// changes rather than the token count, which matters because every span
  /// becomes its own styled run in the archive.
  private static func appendText(_ text: String, role: TokenRole, to spans: inout [Span]) {
    guard !text.isEmpty else {
      return
    }
    if var last = spans.last, last.role == role {
      last.text += text
      spans[spans.count - 1] = last
      return
    }
    spans.append(Span(text: text, role: role))
  }
}
