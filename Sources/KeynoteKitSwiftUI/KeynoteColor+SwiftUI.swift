//
//  KeynoteColor+SwiftUI.swift
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

#if canImport(SwiftUI)
  public import KeynoteKit
  public import SwiftUI

  extension KeynoteColor {
    /// Creates an authoring color from a SwiftUI color, converted to sRGB.
    ///
    /// Because a `.key` is a static document, a dynamic color is resolved
    /// **once**, here — the deck cannot track appearance changes the way a
    /// live view can. Whichever appearance is active when you author is
    /// what gets written.
    ///
    /// ```swift
    /// import KeynoteKitSwiftUI
    ///
    /// TextBox("hello").background(KeynoteColor(.blue))
    /// ```
    @available(macOS 14, iOS 17, tvOS 17, watchOS 10, visionOS 1, *)
    public init(_ color: SwiftUI.Color) {
      let resolved = color.resolve(in: EnvironmentValues())
      self.init(
        red: Self.srgbEncoded(Double(resolved.linearRed)),
        green: Self.srgbEncoded(Double(resolved.linearGreen)),
        blue: Self.srgbEncoded(Double(resolved.linearBlue)),
        opacity: Double(resolved.opacity)
      )
    }

    /// Encodes a linear-light component into sRGB.
    ///
    /// `Color.Resolved` exposes **linear** components while the archive
    /// stores sRGB-encoded ones. Writing the linear value straight through
    /// renders visibly washed out, so apply the transfer function.
    private static func srgbEncoded(_ value: Double) -> Double {
      value <= 0.0031308 ? 12.92 * value : 1.055 * pow(value, 1 / 2.4) - 0.055
    }
  }
#endif
