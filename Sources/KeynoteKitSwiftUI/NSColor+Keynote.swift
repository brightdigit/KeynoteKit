//
//  NSColor+Keynote.swift
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

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  public import AppKit
  public import KeynoteKit

  extension NSColor {
    /// This color as a KeynoteKit authoring color, converted to sRGB.
    ///
    /// `nil` when the color has no sRGB representation — most commonly a
    /// pattern color. Dynamic system colors (`.labelColor` and friends)
    /// resolve against the appearance active at the moment this is called;
    /// a deck is a static document, so that resolution is final.
    public var keynoteColor: KeynoteKit.Color? {
      guard let converted = usingColorSpace(.sRGB) else {
        return nil
      }
      return KeynoteKit.Color(
        red: Double(converted.redComponent),
        green: Double(converted.greenComponent),
        blue: Double(converted.blueComponent),
        opacity: Double(converted.alphaComponent)
      )
    }
  }
#endif
