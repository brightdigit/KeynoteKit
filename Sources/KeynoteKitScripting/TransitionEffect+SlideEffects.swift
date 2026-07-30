//
//  TransitionEffect+SlideEffects.swift
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
  /// Clothesline (`tclo` / `apple:ClotheslinePush`).
  public static let clothesline = TransitionEffect(
    appleScriptName: "clothesline",
    eventCode: AppleEventCode("tclo"),
    archiveValue: "apple:ClotheslinePush"
  )

  /// Dissolve (`tdis` / `apple:dissolve`).
  public static let dissolve = TransitionEffect(
    appleScriptName: "dissolve",
    eventCode: AppleEventCode("tdis"),
    archiveValue: "apple:dissolve"
  )

  /// Drop (`tdrp` / `apple:bounce`).
  public static let drop = TransitionEffect(
    appleScriptName: "drop",
    eventCode: AppleEventCode("tdrp"),
    archiveValue: "apple:bounce"
  )

  /// Droplet (`tdpl` / `apple:droplet`).
  public static let droplet = TransitionEffect(
    appleScriptName: "droplet",
    eventCode: AppleEventCode("tdpl"),
    archiveValue: "apple:droplet"
  )

  /// Grid (`tgrd` / `apple:apple-grid`).
  public static let grid = TransitionEffect(
    appleScriptName: "grid",
    eventCode: AppleEventCode("tgrd"),
    archiveValue: "apple:apple-grid"
  )

  /// Iris (`tirs` / `apple:wipe-iris`).
  public static let iris = TransitionEffect(
    appleScriptName: "iris",
    eventCode: AppleEventCode("tirs"),
    archiveValue: "apple:wipe-iris"
  )

  /// Move In (`tmvi` / `apple:slide`).
  public static let moveIn = TransitionEffect(
    appleScriptName: "move in",
    eventCode: AppleEventCode("tmvi"),
    archiveValue: "apple:slide"
  )

  /// Push (`tpsh` / `apple:push`).
  public static let push = TransitionEffect(
    appleScriptName: "push",
    eventCode: AppleEventCode("tpsh"),
    archiveValue: "apple:push"
  )

  /// Reveal (`trvl` / `apple:reveal`).
  public static let reveal = TransitionEffect(
    appleScriptName: "reveal",
    eventCode: AppleEventCode("trvl"),
    archiveValue: "apple:reveal"
  )

  /// Switch (`tswi` / `apple:FlipThrough`).
  public static let `switch` = TransitionEffect(
    appleScriptName: "switch",
    eventCode: AppleEventCode("tswi"),
    archiveValue: "apple:FlipThrough"
  )

  /// Wipe (`twpe` / `apple:wipe`).
  public static let wipe = TransitionEffect(
    appleScriptName: "wipe",
    eventCode: AppleEventCode("twpe"),
    archiveValue: "apple:wipe"
  )

  /// Cube (`tcub` / `apple:3D-cube`).
  public static let cube = TransitionEffect(
    appleScriptName: "cube",
    eventCode: AppleEventCode("tcub"),
    archiveValue: "apple:3D-cube"
  )

  /// Doorway (`tdwy` / `apple:doorway`).
  public static let doorway = TransitionEffect(
    appleScriptName: "doorway",
    eventCode: AppleEventCode("tdwy"),
    archiveValue: "apple:doorway"
  )

  /// Fall (`tfal` / `apple:fall`).
  public static let fall = TransitionEffect(
    appleScriptName: "fall",
    eventCode: AppleEventCode("tfal"),
    archiveValue: "apple:fall"
  )

  /// Flip (`tfip` / `apple:revolve`).
  public static let flip = TransitionEffect(
    appleScriptName: "flip",
    eventCode: AppleEventCode("tfip"),
    archiveValue: "apple:revolve"
  )

  /// Page Flip (`tpfl` / `apple:pageflip`).
  public static let pageFlip = TransitionEffect(
    appleScriptName: "page flip",
    eventCode: AppleEventCode("tpfl"),
    archiveValue: "apple:pageflip"
  )

  /// Pivot (`tpvt` / `apple:pivot`).
  public static let pivot = TransitionEffect(
    appleScriptName: "pivot",
    eventCode: AppleEventCode("tpvt"),
    archiveValue: "apple:pivot"
  )

  /// Scale (`tscl` / `apple:scale`).
  public static let scale = TransitionEffect(
    appleScriptName: "scale",
    eventCode: AppleEventCode("tscl"),
    archiveValue: "apple:scale"
  )

  /// Twirl (`ttwl` / `apple:twirl`).
  public static let twirl = TransitionEffect(
    appleScriptName: "twirl",
    eventCode: AppleEventCode("ttwl"),
    archiveValue: "apple:twirl"
  )

  /// Fade And Move (`tfad` / `apple:fade-and-move`).
  public static let fadeAndMove = TransitionEffect(
    appleScriptName: "fade and move",
    eventCode: AppleEventCode("tfad"),
    archiveValue: "apple:fade-and-move"
  )

  /// Radial Wipe (`trwp` / `apple:radial wipe`).
  public static let radialWipe = TransitionEffect(
    appleScriptName: "radial wipe",
    eventCode: AppleEventCode("trwp"),
    archiveValue: "apple:radial wipe"
  )
}
