//
//  SyntaxHighlightContent.swift
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

import KeynoteKit
import KeynoteKitSyntax

/// Syntax-highlighted code on slides (#66) for the human render pass.
///
/// Structural tests prove the spans and roles are right; only a human can
/// confirm Keynote *paints* them. Every sample is deliberately several
/// lines long — #81 showed that interior paragraphs fail silently, and code
/// blocks are inherently multi-line.
///
/// Green means:
/// - slide 1: keywords, types, strings, numbers, and the comment are each a
///   distinct colour, on **every** line — not just the first
/// - slide 2: the same code on a dark panel, still legible
/// - slide 3: indentation holds its columns; nothing is monospaced-in-name-only
package struct SyntaxHighlightContent: SlideContent {
  /// A sample exercising every role in one block.
  private static let sample = """
    // Author a deck
    func render(deck: Deck) throws {
      let url: URL = .documentsDirectory
      try deck.write(to: url)
      print("wrote 1 deck")
    }
    """

  /// Deeply indented code, to check column alignment survives.
  private static let indented = """
    struct Outer {
      func middle() {
        for item in items {
          process(item)
        }
      }
    }
    """

  package var body: some SlideContent {
    plainSlide
    panelSlide
    indentationSlide
  }

  /// Highlighted code on the default slide background.
  private var plainSlide: Slide {
    Slide {
      TextBox("1 - every line coloured, not just the first")
        .position(x: 100, y: 60)
        .frame(width: 1_700, height: 70)
        .fontSize(32)
      CodeBlock(Self.sample)
        .position(x: 100, y: 200)
        .frame(width: 1_700, height: 700)
    }
  }

  /// The demo's real treatment: highlighted code on a filled panel.
  private var panelSlide: Slide {
    Slide {
      TextBox("2 - the same code on a panel")
        .position(x: 100, y: 60)
        .frame(width: 1_700, height: 70)
        .fontSize(32)
      CodeBlock(Self.sample)
        .background(CodeTheme.midnightBackground)
        .position(x: 100, y: 200)
        .frame(width: 1_700, height: 700)
    }
  }

  /// Nested indentation, where a proportional substitute would show.
  private var indentationSlide: Slide {
    Slide {
      TextBox("3 - indentation holds its columns")
        .position(x: 100, y: 60)
        .frame(width: 1_700, height: 70)
        .fontSize(32)
      CodeBlock(Self.indented)
        .background(CodeTheme.midnightBackground)
        .position(x: 100, y: 200)
        .frame(width: 1_700, height: 700)
    }
  }

  /// Creates the content.
  package init() {}
}
