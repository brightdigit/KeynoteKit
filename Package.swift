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
    .library(name: "KeynoteKitScripting", targets: ["KeynoteKitScripting"]),
    .library(name: "KeynoteKitSwiftUI", targets: ["KeynoteKitSwiftUI"]),
    .library(name: "KeynoteKitSyntax", targets: ["KeynoteKitSyntax"]),
    // #56 showcase presentation (library) + writer CLI (executable).
    .library(name: "KeynoteKitDemo", targets: ["KeynoteKitDemo"]),
    .executable(name: "KeynoteKitDemoTool", targets: ["KeynoteKitDemoTool"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-protobuf", from: "1.38.1"),
    // Syntax highlighting only (#66). Deliberately NOT a dependency of the
    // `KeynoteKit` target — core must keep its single swift-protobuf
    // dependency, which `KeynoteKitSyntaxTests` asserts.
    .package(url: "https://github.com/apple/swift-syntax", from: "603.0.0")
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

    // SwiftUI color interop, deliberately its OWN target rather than a
    // `canImport(SwiftUI)` block inside `KeynoteKit`.
    //
    // SwiftUI conforms `Never` to `View` and `KeynoteKit` conforms `Never`
    // to `SlideContent` — the primitive terminator the slide DSL needs.
    // Importing SwiftUI anywhere in the core module makes `Never.body`
    // ambiguous and the module stops compiling. Splitting it also keeps
    // `KeynoteKit` linking nothing but swift-protobuf, so authoring still
    // works on Linux, Windows, and Android.
    .target(name: "KeynoteKitSwiftUI", dependencies: ["KeynoteKit"]),

    // Swift syntax highlighting for code on slides (#66). Its own target so
    // that swift-syntax never reaches `KeynoteKit`; authoring a deck must
    // not pull a parser in.
    .target(
      name: "KeynoteKitSyntax",
      dependencies: [
        "KeynoteKit",
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax")
      ]
    ),

    // The five #24 acceptance decks expressed in the public DSL, shared by
    // the acceptance executable and the differential tests. Deliberately not
    // a product: acceptance tooling, not API.
    // Depends on `KeynoteKitSyntax` so the #66 render deck can be authored
    // through the real public API. That puts swift-syntax in the acceptance
    // and test graph, never in `KeynoteKit` itself — `CoreDependencyTests`
    // asserts the distinction.
    .target(
      name: "AcceptanceDeckCatalog",
      dependencies: ["KeynoteKit", "KeynoteKitSyntax"]
    ),

    // `swift run AcceptanceDecks [dir]` writes the five decks for the #24
    // human pass, self-checking each (every record decodes, both SIGTRAP
    // invariants hold) before printing the PLAN Step 6 checklist.
    .executableTarget(
      name: "AcceptanceDecks",
      dependencies: ["AcceptanceDeckCatalog", "IWAFraming", "KeynoteKit", "KeynoteKitProtobuf"]
    ),

    // `swift run ScaleSpike [dir]` — the #63 spike. Times `Deck.write(to:)`
    // across a ladder of slide counts to separate quadratic growth from
    // "slow but linear" (issue #44's `SlideCatalog.locate` cost).
    .executableTarget(name: "ScaleSpike", dependencies: ["KeynoteKit"]),

    // #56 sample presentation — public showcase deck. Depends on
    // `KeynoteKitSyntax` for upcoming code slides; never a dependency of
    // `KeynoteKit` itself.
    .target(
      name: "KeynoteKitDemo",
      dependencies: ["KeynoteKit", "KeynoteKitSyntax"],
      exclude: ["README.md"]
    ),

    // `swift run KeynoteKitDemoTool [dir]` writes `demo.key` from
    // `DemoPresentation.deck` and structurally self-checks before exit.
    .executableTarget(
      name: "KeynoteKitDemoTool",
      dependencies: [
        "KeynoteKitDemo",
        "KeynoteKit",
        "IWAFraming",
        "KeynoteKitProtobuf",
      ]
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
    .testTarget(name: "KeynoteKitScriptingTests", dependencies: ["KeynoteKitScripting"]),
    .testTarget(
      name: "KeynoteKitSyntaxTests",
      dependencies: ["KeynoteKitSyntax", "KeynoteKit"]
    ),
    .testTarget(
      name: "KeynoteKitSwiftUITests",
      dependencies: ["KeynoteKitSwiftUI", "KeynoteKit"]
    )
  ]
)
