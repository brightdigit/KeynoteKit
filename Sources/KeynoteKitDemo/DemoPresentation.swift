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

import Foundation
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
  public static let buildCount = 0

  /// Sample image loaded from the demo target's bundle resources.
  package static var sampleImage: Image? {
    guard let url = Bundle.module.url(forResource: "sample", withExtension: "jpg") else {
      return nil
    }
    return try? Image(contentsOf: url)
  }

  /// The margin every slide insets its content by, in points.
  ///
  /// The only geometry constant the demo needs. A stack child fills the
  /// cross axis by default, so a box spans the padded canvas without naming
  /// a width, and the 1920x1080 size is never restated here. The heights
  /// that remain are real author intent — text cannot measure itself yet.
  private static let margin = 80.0

  /// Title — keep as slide 1 when the tutorial body is authored.
  ///
  /// Spacers above and below centre the pair without naming a y offset.
  private static var titleSlide: Slide {
    Slide {
      VStack(spacing: 40) {
        Spacer()
        TextBox("KeynoteKit")
          .frame(height: 120)
          .fontSize(72)
          .bold()
        TextBox("Authored from Swift — no Keynote required to write")
          .frame(height: 80)
          .fontSize(36)
        Spacer()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(margin)
    }
  }

  /// Mixed character styling within one box.
  private static var stylesSlide: Slide {
    Slide {
      VStack(spacing: 20) {
        TextBox("Supports a variety of styles")
          .frame(height: 180)
          .fontSize(72)
        TextBox {
          Text("Bold").bold().foregroundColor(.init(green: 1.0))
          Text("Italics").italic().foregroundColor(.init(red: 1.0))
        }
        .frame(height: 80)
        .fontSize(36)
        Spacer()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(margin)
    }
  }

  /// The showcase deck.
  ///
  /// Next (#56): grow to the 15–20 slide tutorial body — feature tour,
  /// syntax-highlighted code panels (`KeynoteKitSyntax` + #78 fills),
  /// layout stacks, transitions, and builds.
  public static var deck: Deck {
    Deck {
      titleSlide
      stylesSlide
      if let sampleImage {
        imageSlide(with: sampleImage)
      }
    }
  }

  /// Embedded image beside a text column.
  ///
  /// The image keeps a fixed frame so its aspect ratio holds; the text
  /// column fills whatever is left of the padded canvas. That column's
  /// `maxWidth` is the `HStack`'s *main* axis, so it stays explicit — only
  /// the cross axis fills by default.
  private static func imageSlide(with image: Image) -> Slide {
    Slide {
      HStack(spacing: 60) {
        image.frame(width: 700, height: 450)
        VStack(spacing: 20) {
          TextBox("Embedded Images")
            .frame(height: 80)
            .fontSize(48)
            .bold()
          TextBox(
            "KeynoteKit embeds JPEGs & PNGs natively with "
              + "exact pixel dimensions and optional build effects."
          )
          .frame(height: 160)
          .fontSize(28)
          Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: 450)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(margin)
    }
  }
}
