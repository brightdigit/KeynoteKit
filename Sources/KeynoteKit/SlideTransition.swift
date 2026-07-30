//
//  SlideTransition.swift
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

/// A slide transition: a proven effect plus timing.
///
/// The catalog is acceptance-proven only: `none`, `magicMove`, `dissolve`,
/// `push`, and `moveIn`.
public struct SlideTransition: Sendable {
  /// No transition.
  public static let none = SlideTransition(effect: "none")

  /// Magic Move (`apple:magic-move-implied-motion-path`).
  public static let magicMove = SlideTransition(effect: "apple:magic-move-implied-motion-path")

  /// Dissolve (`apple:dissolve`).
  public static let dissolve = SlideTransition(effect: "apple:dissolve")

  /// Push (`apple:push`).
  public static let push = SlideTransition(effect: "apple:push")

  /// Move In (`apple:slide`).
  public static let moveIn = SlideTransition(effect: "apple:slide")

  /// The raw archive effect string (`none` means no transition).
  internal var effect: String

  /// Seconds.
  internal var durationSeconds: Double = 1.0

  /// Seconds.
  internal var delaySeconds: Double = 0.0

  /// Whether the slide advances automatically.
  internal var autoAdvances: Bool = false

  /// The direction ordinal, for directional effects only.
  internal var directionOrdinal: UInt32?

  /// Sets the transition's duration in seconds.
  public func duration(_ seconds: Double) -> SlideTransition {
    var transition = self
    transition.durationSeconds = seconds
    return transition
  }

  /// Sets the transition's delay in seconds.
  public func delay(_ seconds: Double) -> SlideTransition {
    var transition = self
    transition.delaySeconds = seconds
    return transition
  }

  /// Sets whether the slide advances automatically.
  public func autoAdvance(_ advances: Bool) -> SlideTransition {
    var transition = self
    transition.autoAdvances = advances
    return transition
  }

  /// Sets the transition's direction to a proven ordinal (directional
  /// effects only).
  public func direction(_ direction: TransitionDirection) -> SlideTransition {
    var transition = self
    transition.directionOrdinal = direction.ordinal
    return transition
  }
}
