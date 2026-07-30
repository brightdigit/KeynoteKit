//
//  KeynoteKitScripting.swift
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

/// Namespace for the ScriptingBridge escape hatch (issue #10).
///
/// This module is a typed wrapper over Keynote's AppleScript dictionary for
/// developers who need direct control of a **running** Keynote — it is an
/// escape hatch, never an authoring backend. `Deck.write(to:)` in the
/// `KeynoteKit` product must never require Keynote, and `KeynoteKit` neither
/// imports nor links this product.
///
/// ## What is scriptable here
///
/// - Document lifecycle: create, open, save, export, close.
/// - `make new slide` and `make new text item`.
/// - `transition properties`, limited to the four knobs Keynote exposes:
///   transition effect, transition duration, transition delay, and
///   automatic transition.
///
/// ## What is NOT scriptable (established in the Phase 1–2 research)
///
/// - **Object builds** — absent from Keynote's scripting dictionary entirely;
///   authoring builds is byte-surgery only, via `KeynoteKit`.
/// - **Transition direction** — the `transition settings` record exposes only
///   effect, duration, delay, and automatic transition.
/// - **Per-effect `custom*` options** (`customBounce`,
///   `customTravelDistance`, …) — inspector-only, never in the dictionary.
///
/// The pure value types in this module (`TransitionEffect`,
/// `TransitionSettings`, `ExportFormat`, …) compile on every platform; the
/// types that talk to Keynote are gated on `#if canImport(ScriptingBridge)`
/// and exist only on macOS.
public enum KeynoteKitScripting {
  /// The bundle identifier Keynote registers regardless of how the app
  /// bundle is named on disk.
  ///
  /// The application bundle can be renamed (for example
  /// `Keynote Creator Studio.app`); the bundle identifier still resolves, so
  /// never hard-code a filesystem path to Keynote.
  public static let keynoteBundleIdentifier = "com.apple.iWork.Keynote"
}
