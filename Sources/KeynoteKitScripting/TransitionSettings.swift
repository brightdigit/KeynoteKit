//
//  TransitionSettings.swift
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

/// The scriptable half of a slide transition: Keynote's
/// `transition settings` record (`xset`).
///
/// These four fields are **everything** Keynote's scripting dictionary
/// exposes about a transition. Transition direction and the per-effect
/// `custom*` options (`customBounce`, `customTravelDistance`, …) are not in
/// the record — authoring those requires `KeynoteKit`'s byte-surgery path.
public struct TransitionSettings: Hashable, Sendable {
  /// One field of the `transition settings` record.
  ///
  /// Deliberately a closed `enum`: the record has exactly these four fields
  /// and gaining a fifth would be a scripting-dictionary change worth a
  /// library update.
  public enum Field: CaseIterable, Hashable, Sendable {
    /// `automatic transition` — advance on a timer rather than on click.
    case automaticTransition

    /// `transition delay` — seconds to wait before the transition begins.
    case transitionDelay

    /// `transition duration` — seconds the transition takes.
    case transitionDuration

    /// `transition effect` — which ``TransitionEffect`` plays.
    case transitionEffect

    /// The AppleScript property name, for example `"transition effect"`.
    public var appleScriptName: String {
      switch self {
      case .automaticTransition: "automatic transition"
      case .transitionDelay: "transition delay"
      case .transitionDuration: "transition duration"
      case .transitionEffect: "transition effect"
      }
    }

    /// The four-character Apple event code of the field.
    public var eventCode: AppleEventCode {
      switch self {
      case .automaticTransition: AppleEventCode("xaut")
      case .transitionDelay: AppleEventCode("xdly")
      case .transitionDuration: AppleEventCode("xdur")
      case .transitionEffect: AppleEventCode("xeft")
      }
    }

    /// The Cocoa scripting key the sdef binds the field to, for example
    /// `"KNTransitionEffectName"` — the key used when the record travels as
    /// a keyed dictionary.
    public var cocoaKey: String {
      switch self {
      case .automaticTransition: "KNTransitionAttributesIsAutomatic"
      case .transitionDelay: "KNTransitionAttributesDelay"
      case .transitionDuration: "KNTransitionAttributesDuration"
      case .transitionEffect: "KNTransitionEffectName"
      }
    }
  }

  /// The transition effect to play between this slide and the next.
  public var effect: TransitionEffect

  /// The number of seconds the transition takes.
  public var duration: Double

  /// The number of seconds to wait before the transition begins.
  public var delay: Double

  /// Whether the slide advances automatically (`false` means on click).
  public var isAutomatic: Bool

  /// Creates transition settings.
  ///
  /// - Parameters:
  ///   - effect: The transition effect; defaults to ``TransitionEffect/none``.
  ///   - duration: Seconds the transition takes; defaults to 1.
  ///   - delay: Seconds before the transition begins; defaults to 0.
  ///   - isAutomatic: Whether the slide advances automatically;
  ///     defaults to `false`.
  public init(
    effect: TransitionEffect = .none,
    duration: Double = 1.0,
    delay: Double = 0.0,
    isAutomatic: Bool = false
  ) {
    self.effect = effect
    self.duration = duration
    self.delay = delay
    self.isAutomatic = isAutomatic
  }
}
