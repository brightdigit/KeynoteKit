//
//  KeynoteApplicationScripting.swift
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

  /// The slice of Keynote's `application` scripting class this escape hatch
  /// uses, hand-declared from `Keynote.sdef` rather than checked in as a
  /// full generated header dump.
  ///
  /// `SBApplication` resolves these selectors dynamically from the loaded
  /// scripting dictionary, which is why every member is `optional` — the
  /// declarations exist to give the dynamic proxy a typed Swift surface.
  @objc public protocol KeynoteApplicationScripting {
    /// The `documents` element array (`docu`).
    ///
    /// - Returns: The application's documents as a lazy element array.
    @objc optional func documents() -> SBElementArray

    /// The standard suite `open` command (`aevtodoc`).
    ///
    /// - Parameter file: The file to open, as a URL.
    /// - Returns: The opened document proxy, when Keynote returns one.
    @objc optional func open(_ file: Any?) -> Any?
  }

  extension SBApplication: KeynoteApplicationScripting {}
#endif
