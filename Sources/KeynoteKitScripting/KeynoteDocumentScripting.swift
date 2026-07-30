//
//  KeynoteDocumentScripting.swift
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

  /// The slice of Keynote's `document` scripting class this escape hatch
  /// uses, hand-declared from `Keynote.sdef`.
  ///
  /// Selector spellings follow the shape `sdp` generates for the same sdef
  /// entries (`saveIn:as:`, `closeSaving:savingIn:`,
  /// `exportTo:as:withProperties:`), which is what `SBObject`'s dynamic
  /// dispatch resolves. Enumeration parameters travel as their
  /// four-character codes; see ``AppleEventCode``.
  @objc public protocol KeynoteDocumentScripting {
    /// The `slides` element array (`KnSd`).
    ///
    /// - Returns: The document's slides as a lazy element array.
    @objc optional func slides() -> SBElementArray

    /// The `slide layouts` element array (`KnMs`).
    ///
    /// - Returns: The layouts of the document's theme, by name.
    @objc optional func slideLayouts() -> SBElementArray

    /// The standard suite `save` command (`coresave`).
    ///
    /// - Parameters:
    ///   - file: The destination, as a URL (AppleScript `POSIX file`).
    ///   - fileFormat: The `saveable file format` code — `Knff` for the
    ///     native `.key` format.
    @objc optional func saveIn(_ file: URL?, as fileFormat: UInt)

    /// The standard suite `close` command (`coreclos`).
    ///
    /// - Parameters:
    ///   - saving: A `save options` code; see ``CloseBehavior``.
    ///   - file: Where to save when saving, or `nil` for the default.
    @objc optional func closeSaving(_ saving: UInt, savingIn file: URL?)

    /// Keynote's `export` command (`Knstexpo`).
    ///
    /// - Parameters:
    ///   - file: The destination file, as a URL.
    ///   - format: The `export format` code; see ``ExportFormat``.
    ///   - properties: Optional `export options`, or `nil` for defaults.
    @objc optional func exportTo(
      _ file: URL?,
      as format: UInt,
      withProperties properties: [String: Any]?
    )
  }

  extension SBObject: KeynoteDocumentScripting {}
#endif
