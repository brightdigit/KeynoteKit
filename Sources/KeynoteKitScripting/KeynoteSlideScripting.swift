//
//  KeynoteSlideScripting.swift
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

#if canImport(ScriptingBridge)
  import Foundation
  import ScriptingBridge

  /// The slice of Keynote's `slide` scripting class this escape hatch uses,
  /// hand-declared from `Keynote.sdef`.
  ///
  /// Only `transition properties` is surfaced for animation control — the
  /// dictionary has nothing else. Object builds are absent from the
  /// dictionary entirely and can never be scripted.
  @objc public protocol KeynoteSlideScripting {
    /// The `transition properties` record (`strn`) of the slide.
    @objc optional var transitionProperties: [String: Any] { get }

    /// The `text items` element array (`shtx`).
    ///
    /// - Returns: The slide's text items as a lazy element array.
    @objc optional func textItems() -> SBElementArray

    /// Sets the `transition properties` record (`strn`).
    ///
    /// - Parameter properties: The record, keyed as
    ///   ``TransitionSettings/scriptingBridgeRecord`` lowers it.
    @objc optional func setTransitionProperties(_ properties: [String: Any])

    /// Sets the `base layout` (`smas`, AppleScript synonym `base slide`).
    ///
    /// - Parameter layout: A `slide layout` proxy from
    ///   ``KeynoteDocumentScripting/slideLayouts()``.
    @objc optional func setBaseLayout(_ layout: SBObject?)
  }

  extension SBObject: KeynoteSlideScripting {}
#endif
