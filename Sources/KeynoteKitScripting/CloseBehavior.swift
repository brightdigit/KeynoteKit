//
//  CloseBehavior.swift
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

/// What happens to unsaved changes when a document closes — the standard
/// suite's `save options` enumeration (`savo`).
///
/// A true closed sum type: the standard suite has had exactly these three
/// options since classic Mac OS.
public enum CloseBehavior: CaseIterable, Hashable, Sendable {
  /// `yes` — save changes before closing.
  case saving

  /// `no` — discard changes (`close thisDoc saving no`, the proven flow
  /// after an explicit `save`).
  case notSaving

  /// `ask` — let Keynote prompt the user. Avoid in unattended automation.
  case askingUser

  /// The four-character Apple event code of the enumerator (space-padded,
  /// for example `"yes "`).
  public var eventCode: AppleEventCode {
    switch self {
    case .saving: AppleEventCode("yes ")
    case .notSaving: AppleEventCode("no  ")
    case .askingUser: AppleEventCode("ask ")
    }
  }
}
