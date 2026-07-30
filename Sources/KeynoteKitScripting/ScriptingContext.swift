//
//  ScriptingContext.swift
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

  /// The shared plumbing every wrapper in one scripting session holds: the
  /// `SBApplication`, its error monitor, and object instantiation.
  internal final class ScriptingContext {
    /// The dynamic proxy for the running (or launchable) application.
    internal let application: SBApplication

    /// The installed Apple event failure monitor.
    private let monitor: AppleEventErrorMonitor

    /// Creates a context and installs the error monitor as the
    /// application's ScriptingBridge delegate.
    ///
    /// - Parameters:
    ///   - application: The `SBApplication` proxy to drive.
    ///   - bundleIdentifier: The app's bundle identifier, for error context.
    internal init(application: SBApplication, bundleIdentifier: String) {
      self.application = application
      let monitor = AppleEventErrorMonitor(bundleIdentifier: bundleIdentifier)
      self.monitor = monitor
      application.delegate = monitor
    }

    /// Instantiates a detached scripting object of the given class, the
    /// ScriptingBridge half of `make new`.
    ///
    /// The object is inert until added to an element array; properties are
    /// then applied by explicit setters, which sidesteps ScriptingBridge's
    /// known `make new … with properties` gaps.
    ///
    /// - Parameter scriptingClass: The sdef class name, for example
    ///   `"slide"` or `"text item"`.
    /// - Returns: The detached object, ready to add to an element array.
    /// - Throws: ``KeynoteScriptingError/objectCreationFailed(scriptingClass:)``
    ///   when the dictionary has no such class.
    internal func makeObject(scriptingClass: String) throws -> SBObject {
      guard
        let objectClass = application.class(forScriptingClass: scriptingClass) as? NSObject.Type,
        let object = objectClass.init() as? SBObject
      else {
        throw KeynoteScriptingError.objectCreationFailed(scriptingClass: scriptingClass)
      }
      return object
    }

    /// Rethrows the most recent Apple event failure, if one occurred.
    ///
    /// - Throws: ``KeynoteScriptingError`` when the last command failed.
    internal func confirmSuccess() throws {
      try monitor.confirmSuccess()
    }
  }
#endif
