import KeynoteKit
import Testing

@testable import KeynoteKitSyntax

/// ``CodeBlock`` lowering (#66).
///
/// Every sample is **three or more lines** on purpose. Code blocks are
/// inherently multi-line, and #81 showed that a two-line case exercises only
/// the first and last paragraphs — passing while interior lines stay broken.
@Suite("Code block")
internal struct CodeBlockTests {
  @Test("each source line becomes its own paragraph")
  internal func linesBecomeParagraphs() {
    let block = CodeBlock("let a = 1\nlet b = 2\nlet c = 3")
    #expect(block.textBox.paragraphCount == 3)
  }

  @Test("a trailing newline does not emit a blank paragraph")
  internal func trailingNewlineIgnored() {
    let block = CodeBlock("let a = 1\nlet b = 2\nlet c = 3\n")
    #expect(block.textBox.paragraphCount == 3)
  }

  @Test("blank interior lines survive as empty paragraphs")
  internal func blankInteriorLinesKept() {
    let block = CodeBlock("let a = 1\n\nlet c = 3")
    #expect(block.textBox.paragraphCount == 3)
  }

  @Test("the box text round-trips the source")
  internal func textRoundTrips() {
    let source = "func f() {\n  // note\n  return\n}"
    #expect(CodeBlock(source).textBox.plainText == source)
  }

  @Test("the theme's font reaches the box")
  internal func themeFontApplied() {
    let theme = CodeTheme(fontName: "Courier New", fontSize: 44, colors: [:])
    let box = CodeBlock("let a = 1\nlet b = 2\nlet c = 3", theme: theme).textBox
    #expect(box.itemFontName == "Courier New")
    #expect(box.itemFontSize == 44)
  }

  /// The interior line specifically — the case that silently failed before
  /// #81 and that a two-line sample would not have caught.
  @Test("an interior line carries its own styled spans")
  internal func interiorLineIsStyled() {
    let block = CodeBlock("let a = 1\nfunc middle() {}\nlet c = 3")
    let middle = block.textBox.paragraphTexts[1]
    #expect(middle.contains("func"))
    #expect(block.textBox.styledRunCount(inParagraph: 1) > 1)
  }
}
