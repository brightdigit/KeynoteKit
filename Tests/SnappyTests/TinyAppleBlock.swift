/// The smallest Snappy block in the fixture corpus.
///
/// Captured from `build_action_B.key` / `AnnotationAuthorStorage.iwa`.
internal enum TinyAppleBlock {
  /// The captured block.
  internal static let value = AppleBlock(
    origin: "build_action_B.key/AnnotationAuthorStorage.iwa",
    decodedSHA256: "3333bbb019a711d477f02717423101ea59e890241ccb282b568a34767309a422",
    uncompressedCount: 18,
    hex: """
      12441108F7F1A101120A08D50112030100051800
      """
  )
}
