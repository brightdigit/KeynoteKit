//
//  BuildRecord.swift
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

/// One object build at archive level, mirroring the dictionaries Python's
/// `deckkit.extract_builds` emits (and the committed expected JSON).
package struct BuildRecord: Equatable, Codable, Sendable {
  /// The animation kind: `In`, `Out`, or `Action`.
  package var kind: String?

  /// The archive effect string, such as `apple:dissolve character`.
  package var effect: String

  /// Seconds, from `animationAttributes.duration`.
  package var duration: Double?

  /// Seconds, from `animationAttributes.delay`.
  package var delay: Double?

  /// The effect's direction ordinal, when the effect is directional.
  package var direction: Int?

  /// The target drawable's object identifier, as a digit string.
  package var drawable: String?

  /// The sparse option bag: `customBounce`, `customTravelDistance`,
  /// `customTextDelivery`, `customDeliveryOption`, `delivery`, and
  /// `eventTrigger`, when present. Python's key list also names
  /// `customTwist`, but the 15.3 schema defines `custom_twist` only on
  /// `KN.TransitionAttributesArchive` — a build block can never carry it,
  /// so the key is unreachable on both sides.
  package var options: [String: BuildOptionValue]

  /// Creates a record; see the field documentation for semantics.
  package init(
    kind: String?,
    effect: String,
    duration: Double?,
    delay: Double?,
    direction: Int?,
    drawable: String?,
    options: [String: BuildOptionValue]
  ) {
    self.kind = kind
    self.effect = effect
    self.duration = duration
    self.delay = delay
    self.direction = direction
    self.drawable = drawable
    self.options = options
  }
}
