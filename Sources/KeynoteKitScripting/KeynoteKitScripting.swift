/// Namespace for the ScriptingBridge escape hatch.
///
/// Reserved here and intentionally empty; the body is issue #10. That body will
/// be gated on `#if canImport(ScriptingBridge)` rather than a linked framework,
/// so this module keeps compiling — to an empty module — off Apple platforms.
///
/// This module depends on Apple frameworks only, never on the write path.
public enum KeynoteKitScripting {
  /// Placeholder version, replaced when the escape hatch lands.
  public static let version = "0.1.0"
}
