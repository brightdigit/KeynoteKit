//
//  AppleEventErrorMonitor.swift
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

  /// Captures Apple event failures from an `SBApplication`.
  ///
  /// ScriptingBridge does not throw: without a delegate, event failures
  /// vanish into the console. Installing this monitor as the application's
  /// delegate records the most recent failure so ``confirmSuccess()`` can
  /// rethrow it as a typed ``KeynoteScriptingError`` — including the
  /// Automation (TCC) denial, Apple event error `-1743`.
  internal final class AppleEventErrorMonitor: NSObject, SBApplicationDelegate {
    /// The bundle identifier of the scripted application, for error context.
    private let bundleIdentifier: String

    /// The most recent unreported Apple event failure.
    private var lastError: NSError?

    /// Creates a monitor for the application with the given identity.
    ///
    /// - Parameter bundleIdentifier: The scripted app's bundle identifier.
    internal init(bundleIdentifier: String) {
      self.bundleIdentifier = bundleIdentifier
    }

    /// `SBApplicationDelegate`: records the failure and suppresses
    /// ScriptingBridge's default handling.
    ///
    /// - Parameters:
    ///   - event: The Apple event that failed.
    ///   - error: The failure, carrying the `OSStatus` code.
    /// - Returns: `nil`, standing in for the command's missing result.
    internal func eventDidFail(
      _ event: UnsafePointer<AppleEvent>,
      withError error: any Error
    ) -> Any? {
      lastError = error as NSError
      return nil
    }

    /// Throws the recorded failure, if any, then clears it.
    ///
    /// - Throws: ``KeynoteScriptingError`` when the last command failed.
    internal func confirmSuccess() throws {
      guard let error = lastError else {
        return
      }
      lastError = nil
      throw KeynoteScriptingError(
        appleEventErrorCode: error.code,
        message: error.localizedDescription,
        bundleIdentifier: bundleIdentifier
      )
    }
  }
#endif
