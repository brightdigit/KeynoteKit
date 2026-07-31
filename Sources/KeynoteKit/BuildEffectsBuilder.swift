//
//  BuildEffectsBuilder.swift
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

/// The result builder collecting a build call's effects.
@resultBuilder
public enum BuildEffectsBuilder {
  /// Collects one configured effect.
  public static func buildExpression(_ effect: some BuildEffect) -> [BuildEffectConfiguration] {
    [effect.configuration]
  }

  /// Combines the block's effects.
  public static func buildBlock(
    _ parts: [BuildEffectConfiguration]...
  ) -> [BuildEffectConfiguration] {
    parts.flatMap { $0 }
  }

  /// Supports `for` loops.
  public static func buildArray(
    _ parts: [[BuildEffectConfiguration]]
  ) -> [BuildEffectConfiguration] {
    parts.flatMap { $0 }
  }

  /// Supports `if` without `else`.
  public static func buildOptional(
    _ parts: [BuildEffectConfiguration]?
  ) -> [BuildEffectConfiguration] {
    parts ?? []
  }

  /// Supports the `if` branch of `if`/`else`.
  public static func buildEither(
    first parts: [BuildEffectConfiguration]
  ) -> [BuildEffectConfiguration] {
    parts
  }

  /// Supports the `else` branch of `if`/`else`.
  public static func buildEither(
    second parts: [BuildEffectConfiguration]
  ) -> [BuildEffectConfiguration] {
    parts
  }
}
