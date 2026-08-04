//
//  KeynoteScriptingApplication.swift
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

  /// A running (or launchable) Keynote, driven through ScriptingBridge.
  ///
  /// This is the entry point of the escape hatch. Creating the value does
  /// **not** launch Keynote; the first command that sends an Apple event
  /// will, and requires Automation (TCC) permission — a denial surfaces as
  /// ``KeynoteScriptingError/automationNotPermitted(bundleIdentifier:)``.
  ///
  /// Not thread-safe: drive one instance from one actor or queue.
  public final class KeynoteScriptingApplication {
    /// The shared session plumbing handed to every wrapper.
    private let context: ScriptingContext

    /// Whether Keynote is currently running. Checking does not launch it.
    public var isRunning: Bool { context.application.isRunning }

    /// Connects to Keynote by bundle identifier, without launching it.
    ///
    /// - Parameter bundleIdentifier: The app to script; defaults to
    ///   ``KeynoteKitScripting/keynoteBundleIdentifier``, which resolves
    ///   however the app bundle is named on disk.
    /// - Throws: ``KeynoteScriptingError/applicationNotFound(bundleIdentifier:)``
    ///   when no such app is installed.
    public init(bundleIdentifier: String = KeynoteKitScripting.keynoteBundleIdentifier) throws {
      guard let application = SBApplication(bundleIdentifier: bundleIdentifier) else {
        throw KeynoteScriptingError.applicationNotFound(bundleIdentifier: bundleIdentifier)
      }
      self.context = ScriptingContext(
        application: application,
        bundleIdentifier: bundleIdentifier
      )
    }

    /// `make new document`: creates a document on Keynote's default theme.
    ///
    /// - Returns: A wrapper for the new document.
    /// - Throws: ``KeynoteScriptingError`` when creation fails.
    public func makeDocument() throws -> KeynoteScriptingDocument {
      let object = try context.makeObject(scriptingClass: "document")
      let proxy: KeynoteApplicationScripting = context.application
      guard let documents = proxy.documents?() else {
        throw KeynoteScriptingError.commandFailed(command: "make new document")
      }
      documents.add(object)
      try context.confirmSuccess()
      return KeynoteScriptingDocument(object: object, context: context)
    }

    /// The standard suite `open` command.
    ///
    /// - Parameter url: The `.key` file to open.
    /// - Returns: A wrapper for the opened document.
    /// - Throws: ``KeynoteScriptingError`` when opening fails.
    public func openDocument(at url: URL) throws -> KeynoteScriptingDocument {
      let proxy: KeynoteApplicationScripting = context.application
      let result = proxy.open?(url as NSURL)
      try context.confirmSuccess()
      if let object = result as? SBObject {
        return KeynoteScriptingDocument(object: object, context: context)
      }
      if let object = proxy.documents?().firstObject as? SBObject {
        return KeynoteScriptingDocument(object: object, context: context)
      }
      throw KeynoteScriptingError.commandFailed(command: "open")
    }
  }
#endif
