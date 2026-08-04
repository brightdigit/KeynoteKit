//
//  DeckCodeFormatterTests.swift
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

import Testing

@testable import KeynoteKit
@testable import KeynoteKitSyntax

@Suite("Deck code formatter")
internal struct DeckCodeFormatterTests {
  @Test("detects markdown code fences")
  internal func detectsCodeFences() {
    let formatter = DeckCodeFormatter()
    #expect(formatter.isCodeFence("```swift\nlet x = 1\n```"))
    #expect(formatter.isCodeFence("```\nfunc test() {}\n```"))
    #expect(!formatter.isCodeFence("Just a regular text line"))
  }

  @Test("strips markdown code fences cleanly")
  internal func stripsCodeFences() {
    let formatter = DeckCodeFormatter()
    let raw = "```swift\nlet a = 1\nlet b = 2\nlet c = 3\n```"
    let clean = formatter.stripCodeFence(raw)
    #expect(clean == "let a = 1\nlet b = 2\nlet c = 3")
  }

  @Test("formats raw code into a highlighted CodeBlock with theme")
  internal func formatsCodeBlockWithTheme() {
    let formatter = DeckCodeFormatter(theme: .midnight)
    let raw = "func render() {\n  let x = 42\n  print(x)\n}"
    let codeBlock = formatter.formatCodeText(raw)
    
    #expect(codeBlock.textBox.paragraphCount == 4)
    #expect(codeBlock.textBox.itemFontName == "Menlo")
    #expect(codeBlock.textBox.itemFontSize == 32)
    #expect(codeBlock.textBox.plainText == raw)
  }
}
