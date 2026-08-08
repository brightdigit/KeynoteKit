//
//  ImageSlide.swift
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

/// An embedded image beside a text column.
///
/// The image keeps a fixed frame so its aspect ratio holds; the text column
/// fills whatever is left of the padded canvas. That column's `maxWidth` is
/// the `HStack`'s *main* axis, so it stays explicit — only the cross axis
/// fills by default.
///
/// Resolves to nothing when the resource is missing, so the deck lists this
/// slide unconditionally and the absence never reaches the order file.
internal struct ImageSlide: SlideContent {
  /// The image to embed, or `nil` to omit the slide entirely.
  private let image: Image?

  internal var body: some SlideContent {
    if let image {
      Slide {
        HStack(spacing: 60) {
          image.frame(width: 700, height: 450)
          VStack(spacing: 20) {
            TextBox("Embedded Images")
              .frame(height: 80)
              .fontSize(DemoStyle.headingSize)
              .bold()
            TextBox(
              "KeynoteKit embeds JPEGs & PNGs natively with "
                + "exact pixel dimensions and optional build effects."
            )
            .frame(height: 160)
            .fontSize(DemoStyle.bodySize)
            Spacer()
          }
          .frame(maxWidth: .infinity, maxHeight: 450)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DemoStyle.margin)
      }
    }
  }

  /// Creates the slide from the demo's bundled sample image.
  internal init(image: Image? = DemoResources.sampleImage) {
    self.image = image
  }
}
