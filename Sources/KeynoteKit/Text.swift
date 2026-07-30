//
//  Text.swift
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
public struct Text: Sendable {
  /// The item's string content.
  internal var content: String

  /// The item's x position (Python-parity default 200).
  internal var x: Double = 200

  /// The item's y position (Python-parity default 200).
  internal var y: Double = 200

  /// The Magic Move pairing id, when set (compile-time only in v0.1.0).
  internal var magicIdentifier: String?

  /// The item's builds, in declaration (= delivery) order.
  internal var builds: [BuildEffectConfiguration] = []

  /// The item's action, when set.
  internal var action: MotionPath?

  /// Creates a text item.
  ///
  /// - Parameter content: The string to display.
  public init(_ content: String) {
    self.content = content
  }

  /// Positions the item on the slide.
  public func position(x: Double, y: Double) -> Text {
    var text = self
    text.x = x
    text.y = y
    return text
  }

  /// Tags the item for Magic Move pairing.
  public func magicId(_ identifier: String) -> Text {
    var text = self
    text.magicIdentifier = identifier
    return text
  }

  /// Adds builds of `phase` to the item, in declaration order.
  public func build(
    _ phase: BuildPhase,
    @BuildEffectsBuilder _ effects: () -> [BuildEffectConfiguration]
  ) -> Text {
    var text = self
    for var configuration in effects() {
      configuration.phase = phase
      text.builds.append(configuration)
    }
    return text
  }

  /// Adds an Action build (a motion path) to the item.
  public func action(_ path: () -> MotionPath) -> Text {
    var text = self
    text.action = path()
    return text
  }
}
