//
//  TextBox.swift
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

/// A text item on a slide — the only drawable v0.1.0 authors.
public struct TextBox: Sendable {
  /// The item's string content.
  internal var content: String

  /// The item's x position (Python-parity default 200).
  internal var x: Double = 200

  /// The item's y position (Python-parity default 200).
  internal var y: Double = 200

  /// Authored width in points; `nil` leaves the template placeholder size.
  internal var width: Double?

  /// Authored height in points; `nil` leaves the template placeholder size.
  internal var height: Double?

  /// Layer order; higher values draw above lower ones. `nil` means 0.
  /// Declaration order breaks ties. Final order becomes `drawablesZOrder`.
  internal var zIndex: Int?

  /// Authored font family; `nil` leaves the template style.
  internal var fontName: String?

  /// Authored font size in points; `nil` leaves the template style.
  internal var fontSize: Double?

  /// Authored bold; `nil` leaves the template style.
  internal var isBold: Bool?

  /// Authored italic; `nil` leaves the template style.
  internal var isItalic: Bool?

  /// Authored text color; `nil` leaves the template style.
  internal var color: TextColor?

  /// The Magic Move pairing id, when set (compile-time only in v0.1.0).
  internal var magicIdentifier: String?

  /// The item's builds, in declaration (= delivery) order.
  internal var builds: [BuildEffectConfiguration] = []

  /// The item's actions, in declaration (= delivery) order.
  internal var actions: [MotionPath] = []

  /// Styled spans, when the item was built from runs. Empty means the whole
  /// item is one span styled by the item-level fields above.
  internal var runs: [Text] = []

  /// Creates a text item.
  ///
  /// - Parameter content: The string to display.
  public init(_ content: String) {
    self.content = content
  }

  /// Creates a text item from styled runs. Runs concatenate in declaration
  /// order; item-level modifiers (``font(_:size:)``, ``bold(_:)``, …) style
  /// the whole item, and each run's own style fields override them for that
  /// span only.
  public init(@TextRunsBuilder _ runs: () -> [Text]) {
    let built = runs()
    self.content = built.map(\.content).joined()
    self.runs = built
  }

  /// Positions the item on the slide.
  public func position(x: Double, y: Double) -> TextBox {
    var text = self
    text.x = x
    text.y = y
    return text
  }

  /// Sets the item's size. Unset dimensions leave the template size.
  public func frame(width: Double, height: Double) -> TextBox {
    var text = self
    text.width = width
    text.height = height
    return text
  }

  /// Sets the item's layer order. Higher values draw above lower ones.
  public func zIndex(_ index: Int) -> TextBox {
    var text = self
    text.zIndex = index
    return text
  }

  /// Sets the font family and optional size.
  public func font(_ name: String, size: Double? = nil) -> TextBox {
    var text = self
    text.fontName = name
    if let size {
      text.fontSize = size
    }
    return text
  }

  /// Sets the font size in points.
  public func fontSize(_ size: Double) -> TextBox {
    var text = self
    text.fontSize = size
    return text
  }

  /// Marks the text bold.
  public func bold(_ isBold: Bool = true) -> TextBox {
    var text = self
    text.isBold = isBold
    return text
  }

  /// Marks the text italic.
  public func italic(_ isItalic: Bool = true) -> TextBox {
    var text = self
    text.isItalic = isItalic
    return text
  }

  /// Sets the text color.
  public func foregroundColor(_ color: TextColor) -> TextBox {
    var text = self
    text.color = color
    return text
  }

  /// Tags the item for Magic Move pairing.
  public func magicId(_ identifier: String) -> TextBox {
    var text = self
    text.magicIdentifier = identifier
    return text
  }

  /// Adds builds of `phase` to the item, in declaration order.
  public func build(
    _ phase: BuildPhase,
    @BuildEffectsBuilder _ effects: () -> [BuildEffectConfiguration]
  ) -> TextBox {
    var text = self
    for var configuration in effects() {
      configuration.phase = phase
      text.builds.append(configuration)
    }
    return text
  }

  /// Adds an Action build (a motion path) to the item. Repeated calls
  /// accumulate in declaration order, like ``build(_:_:)``.
  public func action(_ path: () -> MotionPath) -> TextBox {
    var text = self
    text.actions.append(path())
    return text
  }
}
