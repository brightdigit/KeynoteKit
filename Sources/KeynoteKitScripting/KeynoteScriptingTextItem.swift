//
//  KeynoteScriptingTextItem.swift
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

  /// A Keynote text item driven through ScriptingBridge.
  ///
  /// Not thread-safe: drive one instance from one actor or queue.
  public final class KeynoteScriptingTextItem {
    /// The underlying ScriptingBridge proxy.
    private let object: SBObject

    /// The shared session plumbing.
    private let context: ScriptingContext

    /// The proxy viewed through the text-item surface.
    private var proxy: KeynoteTextItemScripting { object }

    /// Wraps a text-item proxy.
    ///
    /// - Parameters:
    ///   - object: The text item's ScriptingBridge proxy.
    ///   - context: The session plumbing shared with the application.
    internal init(object: SBObject, context: ScriptingContext) {
      self.object = object
      self.context = context
    }

    /// Sets the item's `object text`.
    ///
    /// - Parameter text: The new text.
    /// - Throws: ``KeynoteScriptingError`` when setting fails.
    public func setText(_ text: String) throws {
      proxy.setObjectText?(text)
      try context.confirmSuccess()
    }

    /// Sets the item's `position` (top-left corner) — the proven flow is
    /// `set position of _t to {x, y}`.
    ///
    /// - Parameters:
    ///   - x: Horizontal coordinate, in points.
    ///   - y: Vertical coordinate, in points.
    /// - Throws: ``KeynoteScriptingError`` when setting fails.
    public func setPosition(x: Double, y: Double) throws {
      proxy.setPosition?(NSPoint(x: x, y: y))
      try context.confirmSuccess()
    }
  }
#endif
