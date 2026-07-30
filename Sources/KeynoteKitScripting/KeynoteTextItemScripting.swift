//
//  KeynoteTextItemScripting.swift
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

  /// The slice of Keynote's `text item` scripting class (and its inherited
  /// `iWork item` geometry) this escape hatch uses, hand-declared from
  /// `Keynote.sdef`.
  @objc public protocol KeynoteTextItemScripting {
    /// The `position` (`sipo`) of the item's top-left corner, in points.
    @objc optional var position: NSPoint { get }

    /// Sets the `object text` (`pDTx`) of the text item.
    ///
    /// - Parameter text: The text to set; a plain `String` coerces to the
    ///   dictionary's `rich text`.
    @objc optional func setObjectText(_ text: Any?)

    /// Sets the `position` (`sipo`) of the item's top-left corner.
    ///
    /// - Parameter position: The new top-left corner, in points.
    @objc optional func setPosition(_ position: NSPoint)
  }

  extension SBObject: KeynoteTextItemScripting {}
#endif
