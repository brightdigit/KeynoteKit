/// Namespace for Apple's `.iwa` chunk layout over the Snappy block codec.
///
/// Framing and the `.key` zip round-trip land in issue #17.
public enum IWAFraming {
  /// Placeholder version, replaced when framing lands.
  public static let version = "0.1.0"
}
