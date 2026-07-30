//
//  KeynoteScriptingSlide.swift
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

  /// A Keynote slide driven through ScriptingBridge: transition settings
  /// and `make new text item`.
  ///
  /// Transitions here are limited to the four scriptable knobs of
  /// ``TransitionSettings``. Object builds and transition direction are not
  /// in the scripting dictionary at all — author those with `KeynoteKit`.
  ///
  /// Not thread-safe: drive one instance from one actor or queue.
  public final class KeynoteScriptingSlide {
    /// The underlying ScriptingBridge proxy.
    private let object: SBObject

    /// The shared session plumbing.
    private let context: ScriptingContext

    /// The proxy viewed through the slide surface.
    private var proxy: KeynoteSlideScripting { object }

    /// Wraps a slide proxy.
    ///
    /// - Parameters:
    ///   - object: The slide's ScriptingBridge proxy.
    ///   - context: The session plumbing shared with the application.
    internal init(object: SBObject, context: ScriptingContext) {
      self.object = object
      self.context = context
    }

    /// Reads the slide's `transition properties`.
    ///
    /// - Returns: The current transition settings.
    /// - Throws: ``KeynoteScriptingError`` when reading fails.
    public func transitionSettings() throws -> TransitionSettings {
      let record = proxy.transitionProperties ?? [:]
      try context.confirmSuccess()
      return TransitionSettings(scriptingBridgeRecord: record)
    }

    /// Sets the slide's `transition properties` — the proven flow is
    /// `set transition properties to {transition effect:…, …}`.
    ///
    /// - Parameter settings: The transition settings to apply.
    /// - Throws: ``KeynoteScriptingError`` when setting fails.
    public func applyTransitionSettings(_ settings: TransitionSettings) throws {
      proxy.setTransitionProperties?(settings.scriptingBridgeRecord)
      try context.confirmSuccess()
    }

    /// `make new text item`: adds a text item with the given text — the
    /// proven flow is `make new text item with properties {object text:…}`.
    ///
    /// - Parameter text: The item's text.
    /// - Returns: A wrapper for the new text item.
    /// - Throws: ``KeynoteScriptingError`` when creation fails.
    public func makeTextItem(text: String) throws -> KeynoteScriptingTextItem {
      let item = try context.makeObject(scriptingClass: "text item")
      guard let items = proxy.textItems?() else {
        throw KeynoteScriptingError.commandFailed(command: "make new text item")
      }
      items.add(item)
      let itemProxy: KeynoteTextItemScripting = item
      itemProxy.setObjectText?(text)
      try context.confirmSuccess()
      return KeynoteScriptingTextItem(object: item, context: context)
    }
  }
#endif
