//
//  BuildEffectConfiguration.swift
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

/// One configured build effect: the archive effect string plus timing.
///
/// Produced by the effect catalog types (``Dissolve``, ``MoveIn``, …) and
/// consumed by ``TextBox/build(_:_:)``.
public struct BuildEffectConfiguration: Sendable {
  /// The raw archive effect string.
  internal var effect: String

  /// Seconds; Keynote's inspector default.
  internal var duration: Double = 1.0

  /// Seconds.
  internal var delay: Double = 0.0

  /// The start trigger.
  internal var trigger: BuildTrigger = .onClick

  /// The direction ordinal, for directional effects only.
  internal var direction: UInt32?

  /// The phase, stamped by ``TextBox/build(_:_:)``.
  internal var phase: BuildPhase = .in

  /// Creates a configuration for `effect`.
  internal init(effect: String) {
    self.effect = effect
  }
}
