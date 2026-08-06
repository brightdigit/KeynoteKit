//
//  DemoPresentation.swift
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

/// The #56 showcase presentation: a living sample authored through the
/// public KeynoteKit DSL.
///
/// Today this is a **scaffold** — a single title slide that proves the
/// product graph and write path. The finished demo grows to 15–20 slides
/// covering transitions, builds, layout, syntax-highlighted code panels,
/// and background fills. See `Sources/KeynoteKitDemo/README.md`.
///
/// Write it with:
///
/// ```bash
/// swift run KeynoteKitDemoTool ~/Desktop/keynotekit-demo
/// ```
public enum DemoPresentation {
  /// Expected `KN.BuildArchive` count for the structural self-check.
  /// Remains `0` until the stub gains builds.
  public static let buildCount = 0

  /// The showcase deck.
  public static var deck: Deck {
    Deck {
      // Title — keep as slide 1 when the tutorial body is authored.
      Slide {
        TextBox("KeynoteKit")
          .position(x: 120, y: 320)
          .frame(width: 1_680, height: 120)
          .fontSize(72)
          .bold()
        TextBox("Authored from Swift — no Keynote required to write")
          .position(x: 120, y: 480)
          .frame(width: 1_680, height: 80)
          .fontSize(36)
      }
      Slide{
        VStack{
          TextBox("Supports a variety of styles").fontSize(72)
          TextBox(){
            Text("Bold").bold().foregroundColor(.init(green: 1.0))
            Text("Italics").italic().foregroundColor(.init(red: 1.0))
          }
          .fontSize(36)
        }.padding(80)
      }
      // Next (#56): grow to the 15–20 slide tutorial body — feature tour,
      // syntax-highlighted code panels (`KeynoteKitSyntax` + #78 fills),
      // layout stacks, transitions, and builds.
    }
  }
}
