//
//  TransitionSettings+ScriptingBridge.swift
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

  // Lowering to and parsing from the keyed dictionary ScriptingBridge uses
  // for the `transition settings` record.
  extension TransitionSettings {
    /// The record as a ScriptingBridge dictionary, keyed by the sdef's
    /// Cocoa scripting keys (``Field/cocoaKey``) with the effect lowered to
    /// its Cocoa string value (``TransitionEffect/archiveValue``) — the
    /// representation the sdef binds the record's fields to.
    public var scriptingBridgeRecord: [String: Any] {
      [
        Field.transitionEffect.cocoaKey: effect.archiveValue,
        Field.transitionDuration.cocoaKey: duration,
        Field.transitionDelay.cocoaKey: delay,
        Field.automaticTransition.cocoaKey: isAutomatic,
      ]
    }

    /// Parses a ScriptingBridge record dictionary, tolerating missing
    /// fields by falling back to the defaults of ``init(effect:duration:delay:isAutomatic:)``.
    ///
    /// An effect string the catalog does not know is preserved via
    /// ``TransitionEffect/resolving(archiveValue:)``.
    ///
    /// - Parameter record: The dictionary read from a slide's
    ///   `transition properties`.
    public init(scriptingBridgeRecord record: [String: Any]) {
      let archiveValue = record[Field.transitionEffect.cocoaKey] as? String
      self.init(
        effect: archiveValue.map(TransitionEffect.resolving(archiveValue:)) ?? .none,
        duration: record[Field.transitionDuration.cocoaKey] as? Double ?? 1.0,
        delay: record[Field.transitionDelay.cocoaKey] as? Double ?? 0.0,
        isAutomatic: record[Field.automaticTransition.cocoaKey] as? Bool ?? false
      )
    }
  }
#endif
