//
//  KeynoteKitProtobuf.swift
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

/// Namespace for the generated Keynote protobuf messages and the
/// ``TSPRegistryMapping`` table.
///
/// Generated sources are checked in rather than produced at build time, so
/// consumers never need `protoc` and the package has no build-tool plugin.
///
/// The two vendored halves are deliberately from different Keynote releases:
/// the message schema comes from 15.3, while the archive-type registry comes
/// from 14.4, which is the last release the registry was extracted from and is
/// still wire-compatible with the 15.3 messages. ``schemaVersion`` and
/// ``registryVersion`` record that split so a mismatch is visible rather than
/// inferred.
public enum KeynoteKitProtobuf {
  /// The Keynote release the vendored `.proto` schema was taken from.
  public static let schemaVersion = "15.3"

  /// The Keynote release the vendored archive-type registry was taken from.
  public static let registryVersion = "14.4"
}
