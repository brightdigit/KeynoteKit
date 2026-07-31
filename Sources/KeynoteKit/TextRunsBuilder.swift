//
//  TextRunsBuilder.swift
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

/// Collects ``Text`` spans for a mixed-formatting ``TextBox`` item.
@resultBuilder
public enum TextRunsBuilder {
  /// Collects the block's runs.
  public static func buildBlock(_ runs: [Text]...) -> [Text] {
    runs.flatMap { $0 }
  }

  /// Lifts a run into the block.
  public static func buildExpression(_ run: Text) -> [Text] {
    [run]
  }

  /// Supports `if` without `else`.
  public static func buildOptional(_ runs: [Text]?) -> [Text] {
    runs ?? []
  }

  /// Supports `if` / `else` (first branch).
  public static func buildEither(first runs: [Text]) -> [Text] {
    runs
  }

  /// Supports `if` / `else` (second branch).
  public static func buildEither(second runs: [Text]) -> [Text] {
    runs
  }

  /// Supports `for` loops.
  public static func buildArray(_ runs: [[Text]]) -> [Text] {
    runs.flatMap { $0 }
  }
}
