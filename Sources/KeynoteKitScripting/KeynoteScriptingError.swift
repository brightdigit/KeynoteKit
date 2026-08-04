//
//  KeynoteScriptingError.swift
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

/// Errors the ScriptingBridge escape hatch can throw.
public enum KeynoteScriptingError: Error, Equatable, Sendable {
  /// No application with the given bundle identifier is installed.
  case applicationNotFound(bundleIdentifier: String)

  /// macOS denied Apple event Automation (TCC) permission — Apple event
  /// error `-1743`. Grant the calling app access to Keynote under
  /// System Settings › Privacy & Security › Automation.
  case automationNotPermitted(bundleIdentifier: String)

  /// Keynote reported an Apple event failure with the given `OSStatus`
  /// error code.
  case appleEventFailed(code: Int, message: String?)

  /// A scripting class (for example `"slide"`) could not be instantiated.
  case objectCreationFailed(scriptingClass: String)

  /// A command completed without an Apple event error but did not produce
  /// the object it should have (for example `open` returning nothing).
  case commandFailed(command: String)

  /// `errAEEventNotPermitted`: the Apple event error Automation (TCC)
  /// denial reports.
  private static let automationDeniedCode = -1_743

  /// Classifies an Apple event error code, mapping the Automation (TCC)
  /// denial code `-1743` to ``automationNotPermitted(bundleIdentifier:)``.
  ///
  /// - Parameters:
  ///   - appleEventErrorCode: The `OSStatus`-style code Keynote reported.
  ///   - message: A human-readable description of the failure, if any.
  ///   - bundleIdentifier: The bundle identifier of the scripted app.
  public init(appleEventErrorCode: Int, message: String?, bundleIdentifier: String) {
    if appleEventErrorCode == Self.automationDeniedCode {
      self = .automationNotPermitted(bundleIdentifier: bundleIdentifier)
    } else {
      self = .appleEventFailed(code: appleEventErrorCode, message: message)
    }
  }
}
