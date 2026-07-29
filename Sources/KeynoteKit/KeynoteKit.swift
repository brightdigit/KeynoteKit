/// Namespace for the public Keynote authoring API.
///
/// This module must never import or link `ScriptingBridge`; authoring a deck
/// cannot depend on a running copy of Keynote. The AppleScript escape hatch
/// lives in `KeynoteKitScripting` instead.
public enum KeynoteKit {
  /// Placeholder version, replaced when the write path lands.
  public static let version = "0.1.0"
}
