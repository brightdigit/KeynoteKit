//
//  TextListStyle.swift
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

/// How a text box labels its paragraphs: a bullet, a number, or nothing.
///
/// Theme styles (``none``, ``bullet``) reference the template's shipped list
/// styles directly; custom labels and indents author a variation of the
/// matching theme style so every list level's geometry inherits.
public struct TextListStyle: Sendable, Equatable {
  /// The label kind a list style applies.
  internal enum Label: Sendable, Equatable {
    /// The theme's plain (unlabeled) list style.
    case themeNone

    /// The theme's "•" bullet list style.
    case themeBullet

    /// A custom bullet label character.
    case bulletCharacter(String)

    /// Numbered labels in `format`.
    case numbered(NumberFormat)
  }

  /// The theme's plain (no label) style — the default for every text box.
  public static let none = TextListStyle(label: .themeNone)

  /// The theme's "•" bullet style.
  public static let bullet = TextListStyle(label: .themeBullet)

  /// The label kind.
  internal var label: Label

  /// Label indent in points, applied at every list level; `nil` inherits
  /// the theme's per-level indents.
  internal var indentPoints: Double?

  /// Whether applying the style must mint a theme variation (custom label
  /// or indent) rather than reference a shipped theme style.
  internal var requiresMint: Bool {
    guard indentPoints == nil else {
      return true
    }
    switch label {
    case .themeNone, .themeBullet:
      return false
    case .bulletCharacter, .numbered:
      return true
    }
  }

  /// Creates a list style.
  internal init(label: Label, indentPoints: Double? = nil) {
    self.label = label
    self.indentPoints = indentPoints
  }

  /// A bullet using a custom label string (e.g. `"→"`).
  public static func bullet(_ character: String) -> TextListStyle {
    TextListStyle(label: .bulletCharacter(character))
  }

  /// Numbered labels (`1.`, `2.`, …) in `format`.
  public static func numbered(_ format: NumberFormat = .decimal) -> TextListStyle {
    TextListStyle(label: .numbered(format))
  }

  /// Sets the label indent, in points, at every list level.
  public func indent(_ points: Double) -> TextListStyle {
    var style = self
    style.indentPoints = points
    return style
  }
}
