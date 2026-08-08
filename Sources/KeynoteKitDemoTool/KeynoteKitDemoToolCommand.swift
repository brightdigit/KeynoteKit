//
//  KeynoteKitDemoToolCommand.swift
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
import IWAFraming
import KeynoteKit
import KeynoteKitDemo

/// Writes the #56 showcase deck:
/// `swift run KeynoteKitDemoTool [output-directory]` (default `keynotekit-demo`).
///
/// Authored through the public DSL (`DemoDeck.deck`) from the bundled
/// template, then structurally self-checked: every record must decode and
/// the UUID-map invariants must hold. A structural pass does not imply
/// Keynote will open or render the file — that remains a human gate
/// (`docs/RELEASING.md`).
@main
internal enum KeynoteKitDemoToolCommand {
  /// The `KN.BuildArchive` count ``DemoDeck/deck`` is expected to produce.
  ///
  /// An assertion about the deck rather than a property of it, so it lives
  /// beside the ``verify(url:buildCount:)`` that consumes it. Bump it in
  /// the same commit that gives a demo slide its first `.build(...)`, or
  /// the self-check fails.
  private static let expectedBuildCount = 0

  /// Writes `demo.key`, self-checks, and prints next steps.
  internal static func main() throws {
    let directory = outputDirectory()
    try FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: true
    )
    let url = directory.appending(path: "demo.key")
    try DemoDeck.deck.write(to: url)
    try verify(url: url, buildCount: Self.expectedBuildCount)
    print("wrote \(url.path)")
    print(
      """

      Scaffold (#56) — structural self-check passed.
      Open a *copy* in Keynote 15.3 for the human render pass
      (Keynote autosaves in place; never open a pristine write directly).
      The tutorial body (15–20 slides) is still to be authored.
      """
    )
  }

  /// The first command-line argument, or `keynotekit-demo` in the current
  /// directory.
  private static func outputDirectory() -> URL {
    let arguments = CommandLine.arguments
    guard arguments.count > 1 else {
      return URL(filePath: "keynotekit-demo", directoryHint: .isDirectory)
    }
    return URL(filePath: arguments[1], directoryHint: .isDirectory)
  }

  /// Reopens a written deck and applies the structural gates: every record
  /// decodes; the UUID-map invariants hold for the expected build count.
  private static func verify(url: URL, buildCount: Int) throws {
    let bundle = try KeyBundle(contentsOfZip: Array(try Data(contentsOf: url)))
    let surgeon = try KeynoteArchiveSurgeon(bundle: bundle)
    for member in surgeon.members {
      for record in member.records {
        _ = try record.decodedMessages()
      }
    }
    try UUIDMapVerifier.verify(members: surgeon.members, expectedBuildCount: buildCount)
  }
}
