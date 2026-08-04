import Foundation

/// The fixed 24-fixture corpus behind the #17 semantic round-trip gate.
///
/// The list is static rather than a directory glob so that parameterized
/// tests get stable labels and an accidentally empty directory cannot pass
/// vacuously (`research/fixtures/` also holds a screenshot the glob would
/// have to special-case). `FixtureCorpusIntegrityTests` asserts the list
/// matches the on-disk corpus, so drift fails loudly.
internal enum KeyFixtureCorpus {
  /// `research/fixtures/` at the repository root, located relative to this
  /// source file so tests work from any checkout without bundle resources.
  internal static let fixturesDirectory = URL(filePath: String(#filePath))
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appending(path: "research/fixtures")

  /// All 24 fixtures, in name order.
  internal static let all: [KeyFixture] = [
    KeyFixture(name: "build_action_B"),
    KeyFixture(name: "build_cat_A"),
    KeyFixture(name: "build_cat_appear"),
    KeyFixture(name: "build_cat_blur"),
    KeyFixture(name: "build_cat_dissolve"),
    KeyFixture(name: "build_cat_fadein"),
    KeyFixture(name: "build_cat_fademove"),
    KeyFixture(name: "build_cat_flip"),
    KeyFixture(name: "build_cat_movein"),
    KeyFixture(name: "build_cat_scale"),
    KeyFixture(name: "build_cat_shiftscale"),
    KeyFixture(name: "build_fx_A"),
    KeyFixture(name: "build_fx_B"),
    KeyFixture(name: "build_in_A"),
    KeyFixture(name: "build_in_B"),
    KeyFixture(name: "build_order_A"),
    KeyFixture(name: "build_order_B"),
    KeyFixture(name: "build_out_A"),
    KeyFixture(name: "build_out_B"),
    KeyFixture(name: "build_shape_A"),
    KeyFixture(name: "build_shape_B"),
    KeyFixture(name: "builds_base"),
    KeyFixture(name: "direction_A"),
    KeyFixture(name: "direction_B"),
  ]
}
