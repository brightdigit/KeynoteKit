// swift-tools-version: 6.4

import PackageDescription

let package = Package(
  name: "KeynoteKit",
  platforms: [
    .macOS(.v14),
    .iOS(.v17),
    .tvOS(.v17),
    .watchOS(.v10),
    .visionOS(.v1)
  ],
  products: [
    .library(name: "Snappy", targets: ["Snappy"]),
    .library(name: "IWAFraming", targets: ["IWAFraming"]),
    .library(name: "KeynoteKitProtobuf", targets: ["KeynoteKitProtobuf"]),
    .library(name: "KeynoteKit", targets: ["KeynoteKit"]),
    .library(name: "KeynoteKitScripting", targets: ["KeynoteKitScripting"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-protobuf", from: "1.38.1")
  ],
  targets: [
    // Generic Snappy block codec. Nothing Apple-specific lives here — this is
    // the seam that becomes an external dependency in #5.
    .target(name: "Snappy"),

    // Apple's .iwa chunk layout, built on the block codec.
    .target(name: "IWAFraming", dependencies: ["Snappy"]),

    // Generated Keynote 15.3 messages + TSPRegistryMapping (#14).
    .target(
      name: "KeynoteKitProtobuf",
      dependencies: [.product(name: "SwiftProtobuf", package: "swift-protobuf")]
    ),

    // Public authoring API. Must never import or link ScriptingBridge.
    //
    // `blank.key` is the minimal base document for template surgery (#21/#7).
    // `.copy` — not `.process` — because a `.key` is a zip archive whose bytes
    // must survive verbatim; `.process` licenses SwiftPM to transform or rename
    // resources per platform, and today's no-op for an unknown extension is not
    // a guarantee. `.copy` also keeps the resource at a stable, predictable
    // path across the Darwin/Linux/Windows/Android legs.
    //
    // Redistribution caveat (#7): this template is derived from Keynote's
    // `21_basicwhite`, so a small amount of Apple-authored theme content ships
    // in this package — a 2.5 KB `Data/st-*.jpg`, a 50 KB
    // `DocumentStylesheet.iwa`, and three theme-bundle resource locators.
    // Reducing the template from 458 KB minimized this; it did not eliminate
    // it. See the note on `KeynoteTemplate`.
    .target(
      name: "KeynoteKit",
      dependencies: ["IWAFraming", "KeynoteKitProtobuf"],
      resources: [.copy("Resources/blank.key")]
    ),

    // ScriptingBridge escape hatch (#10): typed control of a running
    // Keynote. Never an authoring backend — KeynoteKit must not depend on
    // this. The ScriptingBridge surface is gated on
    // `canImport(ScriptingBridge)` rather than a linked framework, so this
    // module still compiles (to its pure value types) on non-Apple platforms.
    .target(name: "KeynoteKitScripting"),

    // The five #24 acceptance decks expressed in the public DSL, shared by
    // the acceptance executable and the differential tests. Deliberately not
    // a product: acceptance tooling, not API.
    .target(name: "AcceptanceDeckCatalog", dependencies: ["KeynoteKit"]),

    // `swift run AcceptanceDecks [dir]` writes the five decks for the #24
    // human pass, self-checking each (every record decodes, both SIGTRAP
    // invariants hold) before printing the PLAN Step 6 checklist.
    .executableTarget(
      name: "AcceptanceDecks",
      dependencies: ["AcceptanceDeckCatalog", "IWAFraming", "KeynoteKit", "KeynoteKitProtobuf"]
    ),

    .testTarget(name: "SnappyTests", dependencies: ["Snappy"]),
    // Internal archive navigation (#18): package-ACL only, deliberately not a
    // product — reading is test infrastructure and writer plumbing, not API (#6).
    .target(
      name: "KeynoteArchiveNavigation",
      dependencies: ["IWAFraming", "KeynoteKitProtobuf"]
    ),

    // The semantic round-trip gate decodes real fixtures down to protobuf,
    // so these tests need both the container and the schema layers.
    .testTarget(name: "IWAFramingTests", dependencies: ["IWAFraming", "KeynoteKitProtobuf"]),
    .testTarget(
      name: "KeynoteArchiveNavigationTests",
      dependencies: ["KeynoteArchiveNavigation", "IWAFraming", "KeynoteKitProtobuf"],
      exclude: ["Expected"]
    ),
    .testTarget(name: "KeynoteKitProtobufTests", dependencies: ["KeynoteKitProtobuf"]),
    // The golden differential decodes goldens down to protobuf and drives
    // the surgeon directly, so these tests need the container layers too.
    .testTarget(
      name: "KeynoteKitTests",
      dependencies: ["KeynoteKit", "IWAFraming", "KeynoteKitProtobuf", "AcceptanceDeckCatalog"]
    ),
    .testTarget(name: "KeynoteKitScriptingTests", dependencies: ["KeynoteKitScripting"])
  ]
)
