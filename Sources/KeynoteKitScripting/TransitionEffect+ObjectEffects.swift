//
//  TransitionEffect+ObjectEffects.swift
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
  /// Magic Move (`tmjv` / `apple:magic-move-implied-motion-path`).
  public static let magicMove = TransitionEffect(
    appleScriptName: "magic move",
    eventCode: AppleEventCode("tmjv"),
    archiveValue: "apple:magic-move-implied-motion-path"
  )

  /// Shimmer (`tshm` / `apple:ca-text-shimmer`).
  public static let shimmer = TransitionEffect(
    appleScriptName: "shimmer",
    eventCode: AppleEventCode("tshm"),
    archiveValue: "apple:ca-text-shimmer"
  )

  /// Sparkle (`tspk` / `apple:ca-text-sparkle`).
  public static let sparkle = TransitionEffect(
    appleScriptName: "sparkle",
    eventCode: AppleEventCode("tspk"),
    archiveValue: "apple:ca-text-sparkle"
  )

  /// Swing (`tswg` / `apple:ca-swing`).
  public static let swing = TransitionEffect(
    appleScriptName: "swing",
    eventCode: AppleEventCode("tswg"),
    archiveValue: "apple:ca-swing"
  )

  /// Object Cube (`tocb` / `apple:ca-cube`).
  public static let objectCube = TransitionEffect(
    appleScriptName: "object cube",
    eventCode: AppleEventCode("tocb"),
    archiveValue: "apple:ca-cube"
  )

  /// Object Flip (`tofp` / `apple:ca-dissolve-and-flip`).
  public static let objectFlip = TransitionEffect(
    appleScriptName: "object flip",
    eventCode: AppleEventCode("tofp"),
    archiveValue: "apple:ca-dissolve-and-flip"
  )

  /// Object Pop (`topp` / `apple:ca-pop`).
  public static let objectPop = TransitionEffect(
    appleScriptName: "object pop",
    eventCode: AppleEventCode("topp"),
    archiveValue: "apple:ca-pop"
  )

  /// Object Push (`toph` / `apple:ca-push`).
  public static let objectPush = TransitionEffect(
    appleScriptName: "object push",
    eventCode: AppleEventCode("toph"),
    archiveValue: "apple:ca-push"
  )

  /// Object Revolve (`torv` / `apple:ca-revolve`).
  public static let objectRevolve = TransitionEffect(
    appleScriptName: "object revolve",
    eventCode: AppleEventCode("torv"),
    archiveValue: "apple:ca-revolve"
  )

  /// Object Zoom (`tozm` / `apple:ca-zoom`).
  public static let objectZoom = TransitionEffect(
    appleScriptName: "object zoom",
    eventCode: AppleEventCode("tozm"),
    archiveValue: "apple:ca-zoom"
  )

  /// Perspective (`tprs` / `apple:ca-isometric`).
  public static let perspective = TransitionEffect(
    appleScriptName: "perspective",
    eventCode: AppleEventCode("tprs"),
    archiveValue: "apple:ca-isometric"
  )
}
