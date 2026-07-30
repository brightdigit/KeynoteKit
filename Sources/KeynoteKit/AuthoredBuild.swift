//
//  AuthoredBuild.swift
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

/// One object build to author, with its effect already resolved to the raw
/// archive string (the spec-name table lives with the spec loader).
package struct AuthoredBuild: Equatable, Sendable {
  /// The build kind, matching `KN.AnimationAttributesArchive.animationType`.
  package enum Kind: String, Equatable, Sendable {
    /// A Build In.
    case buildIn = "In"

    /// A Build Out.
    case buildOut = "Out"

    /// An Action build (motion path payload).
    case action = "Action"
  }

  /// The build kind.
  package var kind: Kind

  /// The raw archive effect string, such as `apple:dissolve character`.
  package var effect: String

  /// Seconds.
  package var duration: Double

  /// Seconds.
  package var delay: Double

  /// Zero-based index into the slide's drawables (spec `item:<n>`).
  package var targetIndex: Int

  /// The effect's direction ordinal, when directional.
  package var direction: UInt32?

  /// The delivery label; the writer defaults to `All at Once` when `nil`.
  package var delivery: String?

  /// The Action motion path; required when `kind == .action`.
  package var motionPath: AuthoredMotionPath?

  /// Creates a build.
  package init(
    kind: Kind,
    effect: String,
    duration: Double = 1.0,
    delay: Double = 0.0,
    targetIndex: Int,
    direction: UInt32? = nil,
    delivery: String? = nil,
    motionPath: AuthoredMotionPath? = nil
  ) {
    self.kind = kind
    self.effect = effect
    self.duration = duration
    self.delay = delay
    self.targetIndex = targetIndex
    self.direction = direction
    self.delivery = delivery
    self.motionPath = motionPath
  }
}
