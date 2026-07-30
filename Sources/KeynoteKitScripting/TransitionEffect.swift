//
//  TransitionEffect.swift
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

/// A slide transition effect as Keynote's scripting dictionary names it.
///
/// Each value carries the three identities one effect has across Apple's
/// stack: the AppleScript enumerator term, the four-character Apple event
/// code, and the Cocoa string value (which is also the exact string the
/// `.key` archive stores — confirmed by the Phase 1 catalog sweep).
///
/// The full Keynote 15.3 catalog is available as static constants (see
/// ``catalog``) and is string-keyed rather than a frozen `enum` so a future
/// Keynote release's effects can be represented without a library update.
///
/// Only the effect itself is scriptable. **Transition direction and the
/// per-effect `custom*` options are not** — they exist only in the archive
/// and the inspector, never in the scripting dictionary.
public struct TransitionEffect: Hashable, Sendable {
  /// No transition (`tnil` / archive `"none"`).
  public static let none = TransitionEffect(
    appleScriptName: "no transition effect",
    eventCode: AppleEventCode("tnil"),
    archiveValue: "none"
  )

  /// The AppleScript enumerator term, for example `"magic move"`.
  ///
  /// Two-word terms are only valid inside a `tell application "Keynote"`
  /// block — a real gotcha when generating AppleScript source by hand.
  public let appleScriptName: String

  /// The four-character Apple event code of the enumerator.
  public let eventCode: AppleEventCode

  /// The sdef Cocoa string value, for example
  /// `"apple:magic-move-implied-motion-path"`.
  ///
  /// This is byte-for-byte the effect string the `.key` archive stores, so
  /// it doubles as the verification key when reading a saved document.
  public let archiveValue: String

  /// Creates an effect from its three dictionary identities.
  ///
  /// Use this only for effects missing from ``catalog`` (for example one
  /// added by a newer Keynote); prefer the static constants otherwise.
  ///
  /// - Parameters:
  ///   - appleScriptName: The AppleScript enumerator term.
  ///   - eventCode: The four-character Apple event code.
  ///   - archiveValue: The sdef Cocoa string value.
  public init(appleScriptName: String, eventCode: AppleEventCode, archiveValue: String) {
    self.appleScriptName = appleScriptName
    self.eventCode = eventCode
    self.archiveValue = archiveValue
  }
}
