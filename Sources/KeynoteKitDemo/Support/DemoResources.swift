//
//  DemoResources.swift
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

import Foundation
import KeynoteKit

/// The demo target's bundled media.
///
/// The one place `Bundle.module` is touched, so a slide file imports only
/// ``KeynoteKit`` and states its layout rather than its file lookups.
internal enum DemoResources {
  /// Sample photograph, or `nil` when the resource is missing or unreadable.
  ///
  /// Optional rather than force-unwrapped: a missing resource should drop
  /// one slide from the deck, not crash the tool that writes it.
  internal static var sampleImage: Image? {
    guard let url = Bundle.module.url(forResource: "sample", withExtension: "jpg") else {
      return nil
    }
    return try? Image(contentsOf: url)
  }
}
