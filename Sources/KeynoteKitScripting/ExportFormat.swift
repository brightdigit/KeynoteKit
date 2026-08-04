//
//  ExportFormat.swift
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

/// A document export format from Keynote's `export format` enumeration
/// (`Knef`), used by the `export` command.
///
/// String-keyed rather than a frozen `enum` so a format added by a newer
/// Keynote can be represented without a library update; the Keynote 15.3
/// set is available as static constants (see ``catalog``).
public struct ExportFormat: Hashable, Sendable {
  /// HTML (`Khtm`).
  public static let html = ExportFormat(
    appleScriptName: "HTML",
    eventCode: AppleEventCode("Khtm"),
    cocoaValue: "com.apple.iWork.Keynote.exportHTML"
  )

  /// QuickTime movie (`Kmov`).
  public static let quickTimeMovie = ExportFormat(
    appleScriptName: "QuickTime movie",
    eventCode: AppleEventCode("Kmov"),
    cocoaValue: "com.apple.iWork.Keynote.exportQT"
  )

  /// PDF (`Kpdf`).
  public static let pdf = ExportFormat(
    appleScriptName: "PDF",
    eventCode: AppleEventCode("Kpdf"),
    cocoaValue: "com.apple.iWork.Keynote.exportPDF"
  )

  /// One image per slide (`Kimg`).
  public static let slideImages = ExportFormat(
    appleScriptName: "slide images",
    eventCode: AppleEventCode("Kimg"),
    cocoaValue: "com.apple.iWork.Keynote.exportIMG"
  )

  /// Microsoft PowerPoint (`Kppt`).
  public static let microsoftPowerPoint = ExportFormat(
    appleScriptName: "Microsoft PowerPoint",
    eventCode: AppleEventCode("Kppt"),
    cocoaValue: "com.apple.iWork.Keynote.exportPPT"
  )

  /// Keynote '09 (`Kkey`).
  public static let keynote09 = ExportFormat(
    appleScriptName: "Keynote 09",
    eventCode: AppleEventCode("Kkey"),
    cocoaValue: "com.apple.iWork.Keynote.exportKEY"
  )

  /// Every export format Keynote 15.3's scripting dictionary declares.
  public static let catalog: [ExportFormat] = [
    .html, .quickTimeMovie, .pdf, .slideImages, .microsoftPowerPoint,
    .keynote09,
  ]

  /// The AppleScript enumerator term, for example `"QuickTime movie"`.
  public let appleScriptName: String

  /// The four-character Apple event code of the enumerator.
  public let eventCode: AppleEventCode

  /// The sdef Cocoa string value, for example
  /// `"com.apple.iWork.Keynote.exportPDF"`.
  public let cocoaValue: String

  /// Creates an export format from its dictionary identities.
  ///
  /// Use this only for formats missing from ``catalog``; prefer the static
  /// constants otherwise.
  ///
  /// - Parameters:
  ///   - appleScriptName: The AppleScript enumerator term.
  ///   - eventCode: The four-character Apple event code.
  ///   - cocoaValue: The sdef Cocoa string value.
  public init(appleScriptName: String, eventCode: AppleEventCode, cocoaValue: String) {
    self.appleScriptName = appleScriptName
    self.eventCode = eventCode
    self.cocoaValue = cocoaValue
  }
}
