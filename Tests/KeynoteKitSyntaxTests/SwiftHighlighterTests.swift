import KeynoteKit
import Testing

@testable import KeynoteKitSyntax

/// Tokenization and role mapping (#66).
@Suite("Swift highlighter")
internal struct SwiftHighlighterTests {
  /// The property that matters most: a highlighter which drops a character
  /// would corrupt the code on a slide, and nothing downstream would catch
  /// it. Every other assertion here is about *colour*; this one is about
  /// not lying about the source.
  @Test(
    "spans concatenate back to the exact source",
    arguments: [
      "let x = 1",
      "func f() {\n  // note\n  return\n}",
      "let s = \"hi\"\nlet n = 42\n",
      "/* block */ struct S: P { }",
      "",
      "\n\n",
      "let emoji = \"🎉\"  // trailing",
    ]
  )
  internal func spansRoundTrip(source: String) {
    let joined = SwiftHighlighter.default.spans(of: source).map(\.text).joined()
    #expect(joined == source)
  }

  @Test("keywords are tagged")
  internal func keywordsTagged() {
    let spans = SwiftHighlighter.default.spans(of: "let x = 1")
    #expect(role(of: "let", in: spans) == .keyword)
  }

  @Test("string literals include their quotes")
  internal func stringsTagged() {
    let spans = SwiftHighlighter.default.spans(of: "let s = \"hi\"")
    let stringText = spans.filter { $0.role == .string }.map(\.text).joined()
    #expect(stringText == "\"hi\"")
  }

  @Test("numeric literals are tagged")
  internal func numbersTagged() {
    let spans = SwiftHighlighter.default.spans(of: "let n = 42")
    #expect(role(of: "42", in: spans) == .number)
  }

  @Test("line comments are tagged even though they are trivia")
  internal func lineCommentsTagged() {
    let spans = SwiftHighlighter.default.spans(of: "let x = 1 // why\n")
    #expect(role(of: "// why", in: spans) == .comment)
  }

  @Test("block comments are tagged")
  internal func blockCommentsTagged() {
    let spans = SwiftHighlighter.default.spans(of: "/* note */ let x = 1")
    #expect(role(of: "/* note */", in: spans) == .comment)
  }

  /// The role that needs parent-node context: the same token text is a type
  /// in one position and a plain identifier in another.
  @Test("an identifier in type position is a type, elsewhere it is plain")
  internal func typePositionDistinguished() {
    let typed = SwiftHighlighter.default.spans(of: "let value: Duration = x")
    #expect(role(of: "Duration", in: typed) == .type)

    let called = SwiftHighlighter.default.spans(of: "let value = Duration()")
    #expect(role(of: "Duration", in: called) != .type)
  }

  @Test("adjacent spans of the same role merge")
  internal func adjacentSpansMerge() {
    let spans = SwiftHighlighter.default.spans(of: "a b c")
    // Identifiers and the spaces between them are all plain, so the whole
    // line collapses to one span rather than five.
    #expect(spans.count == 1)
    #expect(spans[0].role == .plain)
  }

  /// The role of the span whose text is `text`, if any.
  private func role(
    of text: String,
    in spans: [SwiftHighlighter.Span]
  ) -> TokenRole? {
    spans.first { $0.text == text }?.role
  }
}
