#!/bin/bash

# Remove set -e to allow script to continue running
# set -e  # Exit on any error

ERRORS=0

run_command() {
	"$@" || ERRORS=$((ERRORS + 1))
}

if [ "$LINT_MODE" = "INSTALL" ]; then
	exit
fi

echo "LintMode: $LINT_MODE"

# More portable way to get script directory
if [ -z "$SRCROOT" ]; then
	SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
	PACKAGE_DIR="${SCRIPT_DIR}/.."
else
	PACKAGE_DIR="${SRCROOT}"
fi

# Detect if mise is available
# Check common installation paths for mise
MISE_PATHS=(
    "/opt/homebrew/bin/mise"
    "/usr/local/bin/mise"
    "$HOME/.local/bin/mise"
)

MISE_BIN=""
for mise_path in "${MISE_PATHS[@]}"; do
    if [ -x "$mise_path" ]; then
        MISE_BIN="$mise_path"
        break
    fi
done

# Fallback to PATH lookup
if [ -z "$MISE_BIN" ] && command -v mise &> /dev/null; then
    MISE_BIN="mise"
fi

if [ -n "$MISE_BIN" ]; then
    TOOL_CMD="$MISE_BIN exec --"
else
    echo "Error: mise is not installed"
    echo "Install mise: https://mise.jdx.dev/getting-started.html"
    echo "Checked paths: ${MISE_PATHS[*]}"
    exit 1
fi

if [ "$LINT_MODE" = "NONE" ]; then
	exit
elif [ "$LINT_MODE" = "STRICT" ]; then
	SWIFTFORMAT_LINT_OPTIONS="--strict"
	SWIFTLINT_OPTIONS="--strict"
else
	SWIFTFORMAT_LINT_OPTIONS=""
	SWIFTLINT_OPTIONS=""
fi

pushd $PACKAGE_DIR

# Bootstrap tools (mise will install based on .mise.toml)
run_command "$MISE_BIN" install

if [ -z "$CI" ]; then
	run_command $TOOL_CMD swift-format format --configuration .swift-format --recursive --parallel --in-place Sources Tests
	run_command $TOOL_CMD swiftlint --fix
fi

if [ -z "$FORMAT_ONLY" ]; then
	run_command $TOOL_CMD swift-format lint --configuration .swift-format --recursive --parallel $SWIFTFORMAT_LINT_OPTIONS Sources Tests
	run_command $TOOL_CMD swiftlint lint $SWIFTLINT_OPTIONS

	# The write path must never reach ScriptingBridge — that is what keeps
	# authoring a deck independent of a running copy of Keynote. Matches import
	# statements only, so documentation may still name the framework.
	if grep -rnE '^[[:space:]]*(@[a-zA-Z]+[[:space:]]+)?import[[:space:]]+ScriptingBridge' \
		Sources/KeynoteKit Sources/IWAFraming Sources/Snappy Sources/KeynoteKitProtobuf; then
		echo "error: ScriptingBridge imported in the write path"
		ERRORS=$((ERRORS + 1))
	fi

	# Check for compilation errors. Swift 6.4 lives in Xcode-beta here; CI
	# overrides DEVELOPER_DIR with its own Xcode. Plain `swift` is 6.3.2 and
	# cannot parse a tools-version 6.4 manifest.
	run_command env DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}" \
		xcrun swift build --build-tests --enable-index-store
fi

# header.sh rewrites file headers in place, so it only runs locally — never in CI.
if [ -z "$CI" ]; then
	$PACKAGE_DIR/Scripts/header.sh -d $PACKAGE_DIR/Sources -c "Leo Dion" -o "BrightDigit" -p "KeynoteKit"
fi

# Periphery runs locally now that #16/#17 landed real implementations (CI's
# lint leg still skips it; SKIP_PERIPHERY=1 opts out for quick local runs).
if [ -z "$CI" ] && [ -z "$SKIP_PERIPHERY" ]; then
	# The build step above populates the index store (--enable-index-store);
	# hand periphery that path so it skips its own toolchain-default build.
	run_command env DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}" \
		$TOOL_CMD periphery scan $PERIPHERY_OPTIONS --disable-update-check \
		--index-store-path .build/debug/index/store
fi

popd

# Exit with error code if any errors occurred
if [ $ERRORS -gt 0 ]; then
	echo "Linting completed with $ERRORS error(s)"
	exit 1
else
	echo "Linting completed successfully"
	exit 0
fi
