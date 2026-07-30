import Foundation

@testable import KeynoteKit

/// Loads the committed golden specs (`research/examples/*.json`) into the
/// writer's ``AuthoredDeck`` model, mirroring Python `deck_from_dict`.
internal enum DeckSpec {
  /// `BUILD_EFFECTS` from `research/tools/deckkit.py:109-118`.
  internal static let buildEffects: [String: String] = [
    "appear": "apple:bc-appear",
    "blur": "apple:blur character",
    "dissolve": "apple:dissolve character",
    "fade_and_move": "apple:fade and move character",
    "fade_in": "com.apple.iWork.Keynote.FromDarkness",
    "flip": "apple:bc-flip",
    "move_in": "apple:move in character",
    "scale": "apple:zoom character",
  ]

  /// Decodes a spec file into the surgeon's model.
  internal static func load(_ url: URL) throws -> AuthoredDeck {
    let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
    guard let root = object as? [String: Any],
      let slides = root["slides"] as? [[String: Any]]
    else {
      throw CocoaError(.coderReadCorrupt)
    }
    return AuthoredDeck(slides: try slides.map(slide(from:)))
  }

  private static func slide(from dictionary: [String: Any]) throws -> AuthoredSlide {
    let items = dictionary["items"] as? [[String: Any]] ?? []
    let transition = dictionary["transition"] as? [String: Any]
    let builds = dictionary["builds"] as? [[String: Any]] ?? []
    return AuthoredSlide(
      itemCount: items.count,
      transitionDirection: (transition?["direction"] as? Int).map(UInt32.init),
      builds: try builds.map(build(from:))
    )
  }

  private static func build(from dictionary: [String: Any]) throws -> AuthoredBuild {
    let kindName = dictionary["kind"] as? String ?? "In"
    guard let kind = AuthoredBuild.Kind(rawValue: kindName) else {
      throw CocoaError(.coderReadCorrupt)
    }
    let effectName = dictionary["effect"] as? String ?? "dissolve"
    let effect = kind == .action ? effectName : (buildEffects[effectName] ?? effectName)
    let target = dictionary["target"] as? String ?? "item:0"
    guard let targetIndex = Int(target.dropFirst("item:".count)) else {
      throw CocoaError(.coderReadCorrupt)
    }
    let options = dictionary["options"] as? [String: Any] ?? [:]
    let action = dictionary["action_attributes"] as? [String: Any] ?? [:]
    return AuthoredBuild(
      kind: kind,
      effect: effect,
      duration: dictionary["duration"] as? Double ?? 1.0,
      delay: dictionary["delay"] as? Double ?? 0.0,
      targetIndex: targetIndex,
      direction: (options["direction"] as? Int).map(UInt32.init),
      delivery: options["delivery"] as? String,
      motionPath: motionPath(from: action)
    )
  }

  private static func motionPath(from action: [String: Any]) -> AuthoredMotionPath? {
    guard let source = action["actionMotionPathSource"] as? [String: Any],
      let bezier = source["editableBezierPathSource"] as? [String: Any],
      let size = bezier["naturalSize"] as? [String: Any],
      let subpaths = bezier["subpaths"] as? [[String: Any]],
      let nodes = subpaths.first?["nodes"] as? [[String: Any]]
    else {
      return nil
    }
    let points = nodes.compactMap { node -> AuthoredMotionPath.Point? in
      guard let nodePoint = node["nodePoint"] as? [String: Any],
        let xValue = nodePoint["x"] as? Double,
        let yValue = nodePoint["y"] as? Double
      else {
        return nil
      }
      return AuthoredMotionPath.Point(x: xValue, y: yValue)
    }
    return AuthoredMotionPath(
      naturalWidth: size["width"] as? Double ?? 0,
      naturalHeight: size["height"] as? Double ?? 0,
      points: points
    )
  }
}
