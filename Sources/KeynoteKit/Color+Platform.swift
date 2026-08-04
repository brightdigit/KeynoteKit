//
//  Color+Platform.swift
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

#if canImport(CoreGraphics)
  public import CoreGraphics

  extension Color {
    /// Creates a color from a `CGColor`, converting to sRGB.
    ///
    /// Returns `nil` when the color cannot be represented in sRGB — a
    /// pattern color has no components to convert, and conversion from an
    /// exotic space can fail outright. Prefer failing visibly over writing
    /// a color that renders differently than the caller intended.
    public init?(cgColor: CGColor) {
      guard
        let space = CGColorSpace(name: CGColorSpace.sRGB),
        let converted = cgColor.converted(
          to: space,
          intent: .defaultIntent,
          options: nil
        ),
        let components = converted.components,
        components.count >= 3
      else {
        return nil
      }
      self.init(
        red: Double(components[0]),
        green: Double(components[1]),
        blue: Double(components[2]),
        opacity: components.count >= 4 ? Double(components[3]) : 1
      )
    }
  }
#endif
