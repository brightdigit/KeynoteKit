//
//  KeynoteScriptingDocument.swift
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

  /// A Keynote document driven through ScriptingBridge: `make new slide`,
  /// save, export, and close.
  ///
  /// Not thread-safe: drive one instance from one actor or queue.
  public final class KeynoteScriptingDocument {
    /// The `saveable file format` code of the native `.key` format.
    private static let keynoteFileFormat = AppleEventCode("Knff")

    /// The underlying ScriptingBridge proxy.
    private let object: SBObject

    /// The shared session plumbing.
    private let context: ScriptingContext

    /// The proxy viewed through the document surface.
    private var proxy: KeynoteDocumentScripting { object }

    /// Wraps a document proxy.
    ///
    /// - Parameters:
    ///   - object: The document's ScriptingBridge proxy.
    ///   - context: The session plumbing shared with the application.
    internal init(object: SBObject, context: ScriptingContext) {
      self.object = object
      self.context = context
    }

    /// `make new slide`: appends a slide, optionally based on a named
    /// slide layout (AppleScript `base slide`, for example `"Blank"`).
    ///
    /// - Parameter layoutName: The slide layout to base the slide on, or
    ///   `nil` for Keynote's default.
    /// - Returns: A wrapper for the new slide.
    /// - Throws: ``KeynoteScriptingError`` when creation fails.
    public func makeSlide(baseLayoutNamed layoutName: String? = nil) throws
      -> KeynoteScriptingSlide
    {
      let slide = try context.makeObject(scriptingClass: "slide")
      guard let slides = proxy.slides?() else {
        throw KeynoteScriptingError.commandFailed(command: "make new slide")
      }
      slides.add(slide)
      if let layoutName {
        let layout = proxy.slideLayouts?().object(withName: layoutName) as? SBObject
        let slideProxy: KeynoteSlideScripting = slide
        slideProxy.setBaseLayout?(layout)
      }
      try context.confirmSuccess()
      return KeynoteScriptingSlide(object: slide, context: context)
    }

    /// The document's slides, front to back.
    ///
    /// - Returns: A wrapper for every slide in the document.
    /// - Throws: ``KeynoteScriptingError`` when enumeration fails.
    public func slides() throws -> [KeynoteScriptingSlide] {
      guard let array = proxy.slides?() else {
        throw KeynoteScriptingError.commandFailed(command: "slides")
      }
      let objects = array.compactMap { $0 as? SBObject }
      try context.confirmSuccess()
      return objects.map { KeynoteScriptingSlide(object: $0, context: context) }
    }

    /// The standard suite `save` command, in the native `.key` format —
    /// the proven flow is `save thisDoc in POSIX file …`.
    ///
    /// - Parameter url: The destination `.key` file.
    /// - Throws: ``KeynoteScriptingError`` when saving fails.
    public func save(to url: URL) throws {
      proxy.saveIn?(url, as: UInt(Self.keynoteFileFormat.rawValue))
      try context.confirmSuccess()
    }

    /// Keynote's `export` command.
    ///
    /// - Parameters:
    ///   - url: The destination file or directory (format-dependent).
    ///   - format: The export format, for example ``ExportFormat/pdf``.
    /// - Throws: ``KeynoteScriptingError`` when exporting fails.
    public func export(to url: URL, format: ExportFormat) throws {
      proxy.exportTo?(url, as: UInt(format.eventCode.rawValue), withProperties: nil)
      try context.confirmSuccess()
    }

    /// The standard suite `close` command — the proven flow after an
    /// explicit save is `close thisDoc saving no`.
    ///
    /// - Parameter behavior: What to do with unsaved changes; defaults to
    ///   ``CloseBehavior/notSaving``.
    /// - Throws: ``KeynoteScriptingError`` when closing fails.
    public func close(_ behavior: CloseBehavior = .notSaving) throws {
      proxy.closeSaving?(UInt(behavior.eventCode.rawValue), savingIn: nil)
      try context.confirmSuccess()
    }
  }
#endif
