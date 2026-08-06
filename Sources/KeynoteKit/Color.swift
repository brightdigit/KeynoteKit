//
//  Color.swift
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

/// An sRGB color, used wherever KeynoteKit takes a color — text
/// (``Text/foregroundColor(_:)``) and shape fills
/// (``TextBox/background(_:)``).
///
/// Modelled on SwiftUI's `Color`: components are `Double`s in `0...1`,
/// opacity defaults to opaque, and the same `white:` convenience exists for
/// greys. Values outside `0...1` are clamped on init — the archive stores
/// `Float` components that Keynote reads as sRGB, and out-of-range values
/// there produce undefined rendering rather than a clean error.
///
/// ```swift
/// TextBox("hello")
///   .foregroundColor(.white)
///   .background(Color(red: 0.11, green: 0.13, blue: 0.17))
/// ```
///
/// On platforms that have them, initialize from the system color types
/// instead — see ``init(_:)-(SwiftUI.Color)`` and its `CGColor` and
/// `NSColor`/`UIColor` counterparts. Those live behind `canImport` checks,
/// so `KeynoteKit` still builds on Linux and Windows with no extra
/// dependency.
///
/// Named colors are deliberately limited to the handful below. KeynoteKit
/// authors decks rather than draws UI, so a full palette would be noise;
/// author the exact value you want.
public struct Color: Equatable, Sendable {
  /// Opaque black.
  public static let black = Color(white: 0)

  /// Opaque white.
  public static let white = Color(white: 1)

  /// Fully transparent.
  public static let clear = Color(white: 0, opacity: 0)

  /// Red channel in 0...1.
  public var red: Double

  /// Green channel in 0...1.
  public var green: Double

  /// Blue channel in 0...1.
  public var blue: Double

  /// Opacity in 0...1, where 1 is fully opaque.
  public var opacity: Double

  /// Creates an sRGB color. Components are clamped to `0...1`.
  public init(red: Double = 0, green: Double = 0, blue: Double = 0, opacity: Double = 1) {
    self.red = Self.clamped(red)
    self.green = Self.clamped(green)
    self.blue = Self.clamped(blue)
    self.opacity = Self.clamped(opacity)
  }

  /// Creates a grey. Components are clamped to `0...1`.
  public init(white: Double = 0, opacity: Double = 1) {
    self.init(red: white, green: white, blue: white, opacity: opacity)
  }

  /// Clamps a component into `0...1`.
  private static func clamped(_ value: Double) -> Double {
    min(max(value, 0), 1)
  }

  /// Returns this color with a different opacity, mirroring SwiftUI's
  /// `Color.opacity(_:)`.
  public func opacity(_ opacity: Double) -> Color {
    var color = self
    color.opacity = Self.clamped(opacity)
    return color
  }
}
