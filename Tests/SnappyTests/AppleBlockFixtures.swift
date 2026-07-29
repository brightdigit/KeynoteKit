/// Real Snappy blocks lifted from the `.iwa` components of the committed
/// Keynote fixtures in `research/fixtures/`.
///
/// These are Apple's own encoder output, so decoding them proves the codec
/// handles production bytes rather than only agreeing with itself. The set
/// spans the smallest block in the corpus up to one sitting exactly on Apple's
/// 64 KiB chunk boundary.
///
/// Each block lives in its own file, stored as hex, so the corpus stays cheap
/// in git and readable in review.
internal enum AppleBlockFixtures {
  /// Every captured block.
  internal static let all: [AppleBlock] = [
    TinyAppleBlock.value,
    SmallAppleBlock.value,
    MediumAppleBlock.value,
    ChunkBoundaryAppleBlock.value,
  ]
}
