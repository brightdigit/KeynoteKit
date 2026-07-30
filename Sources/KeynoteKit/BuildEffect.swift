//
//  BuildEffect.swift
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

/// A catalog build effect that can be configured fluently.
///
/// The catalog is acceptance-proven only (Exp 9): conforming types wrap the
/// archive effect strings measured in `research/findings/build_catalog.md`.
public protocol BuildEffect {
  /// The effect's configuration; modifiers copy and update it.
  var configuration: BuildEffectConfiguration { get set }
}

extension BuildEffect {
  /// Sets the effect's duration in seconds.
  public func duration(_ seconds: Double) -> Self {
    var effect = self
    effect.configuration.duration = seconds
    return effect
  }

  /// Sets the effect's delay in seconds.
  public func delay(_ seconds: Double) -> Self {
    var effect = self
    effect.configuration.delay = seconds
    return effect
  }

  /// Sets the effect's start trigger.
  public func trigger(_ trigger: BuildTrigger) -> Self {
    var effect = self
    effect.configuration.trigger = trigger
    return effect
  }
}
