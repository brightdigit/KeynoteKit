//
//  TemplateError.swift
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

/// A failure resolving or reading the base template a deck is authored from.
public enum TemplateError: Error, Equatable, Sendable {
  /// The bundled `blank.key` resource was not found in `Bundle.module`.
  ///
  /// `Bundle.module` resolves differently for executables, tests, and
  /// statically linked builds, and it fails at *runtime* rather than build
  /// time. This error means the package's resource bundle was stripped,
  /// relocated, or never copied alongside the binary.
  case bundledResourceMissing
}

extension TemplateError: CustomStringConvertible {
  /// A human-readable description of the failure.
  public var description: String {
    switch self {
    case .bundledResourceMissing:
      return """
        KeynoteKit's bundled template resource was not found in Bundle.module. \
        The package resource bundle is missing from the built product.
        """
    }
  }
}
