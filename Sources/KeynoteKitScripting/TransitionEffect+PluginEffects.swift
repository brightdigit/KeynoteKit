//
//  TransitionEffect+PluginEffects.swift
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

extension TransitionEffect {
  /// Confetti (`tcft` / `com.apple.iWork.Keynote.KLNConfetti`).
  public static let confetti = TransitionEffect(
    appleScriptName: "confetti",
    eventCode: AppleEventCode("tcft"),
    archiveValue: "com.apple.iWork.Keynote.KLNConfetti"
  )

  /// Fade Through Color (`tftc` / `com.apple.iWork.Keynote.BLTFadeThruColor`).
  public static let fadeThroughColor = TransitionEffect(
    appleScriptName: "fade through color",
    eventCode: AppleEventCode("tftc"),
    archiveValue: "com.apple.iWork.Keynote.BLTFadeThruColor"
  )

  /// Blinds (`tbld` / `com.apple.iWork.Keynote.BLTBlinds`).
  public static let blinds = TransitionEffect(
    appleScriptName: "blinds",
    eventCode: AppleEventCode("tbld"),
    archiveValue: "com.apple.iWork.Keynote.BLTBlinds"
  )

  /// Color Planes (`tcpl` / `com.apple.iWork.Keynote.KLNColorPlanes`).
  public static let colorPlanes = TransitionEffect(
    appleScriptName: "color planes",
    eventCode: AppleEventCode("tcpl"),
    archiveValue: "com.apple.iWork.Keynote.KLNColorPlanes"
  )

  /// Flop (`tfop` / `com.apple.iWork.Keynote.BUKFlop`).
  public static let flop = TransitionEffect(
    appleScriptName: "flop",
    eventCode: AppleEventCode("tfop"),
    archiveValue: "com.apple.iWork.Keynote.BUKFlop"
  )

  /// Mosaic (`tmsc` / `com.apple.iWork.Keynote.BLTMosaicFlip`).
  public static let mosaic = TransitionEffect(
    appleScriptName: "mosaic",
    eventCode: AppleEventCode("tmsc"),
    archiveValue: "com.apple.iWork.Keynote.BLTMosaicFlip"
  )

  /// Reflection (`trfl` / `com.apple.iWork.Keynote.BLTReflection`).
  public static let reflection = TransitionEffect(
    appleScriptName: "reflection",
    eventCode: AppleEventCode("trfl"),
    archiveValue: "com.apple.iWork.Keynote.BLTReflection"
  )

  /// Revolving Door (`trev` / `com.apple.iWork.Keynote.BLTRevolvingDoor`).
  public static let revolvingDoor = TransitionEffect(
    appleScriptName: "revolving door",
    eventCode: AppleEventCode("trev"),
    archiveValue: "com.apple.iWork.Keynote.BLTRevolvingDoor"
  )

  /// Swap (`tswp` / `com.apple.iWork.Keynote.KLNSwap`).
  public static let swap = TransitionEffect(
    appleScriptName: "swap",
    eventCode: AppleEventCode("tswp"),
    archiveValue: "com.apple.iWork.Keynote.KLNSwap"
  )

  /// Swoosh (`tsws` / `com.apple.iWork.Keynote.BLTSwoosh`).
  public static let swoosh = TransitionEffect(
    appleScriptName: "swoosh",
    eventCode: AppleEventCode("tsws"),
    archiveValue: "com.apple.iWork.Keynote.BLTSwoosh"
  )

  /// Twist (`ttwi` / `com.apple.iWork.Keynote.BUKTwist`).
  public static let twist = TransitionEffect(
    appleScriptName: "twist",
    eventCode: AppleEventCode("ttwi"),
    archiveValue: "com.apple.iWork.Keynote.BUKTwist"
  )
}
