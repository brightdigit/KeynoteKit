#!/usr/bin/env python3
"""Generate an authored deck and ask Keynote to reopen it.

No arguments: the original acceptance case (examples/build_acceptance.json ->
samples/build_backend_acceptance.key).

With arguments: any spec/output pair, e.g. the bisect decks of
findings/write_backend_bisect.md:

    python3 tools/authored_build_smoke.py examples/bisect_in.json samples/bisect_in.key

Expected slide/text-item counts are derived from the spec, so a one-slide bisect
deck is checked against its own shape rather than the acceptance deck's.

NOTE: --no-reopen generates only. The reopen check drives Keynote via osascript,
and a real Keynote crash surfaces here as AppleEvent -10000 / -609 rather than a
clean signal (findings/write_backend.md), so a failure from this script is NOT
sufficient evidence of the crash: open the artifact by hand to confirm.
"""
from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

import deckkit

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SPEC = ROOT / "examples/build_acceptance.json"
DEFAULT_OUTPUT = ROOT / "samples/build_backend_acceptance.key"


def _reopen_script(output: Path, counts: list[int]) -> str:
    """AppleScript asserting slide count and per-slide text-item counts."""
    checks = [f"count of slides is not {len(counts)}"]
    lines = []
    for idx, n in enumerate(counts, start=1):
        var = f"c{idx}"
        lines.append(f"    set {var} to count of text items of slide {idx}")
        checks.append(f"{var} is not {n}")
    body = "\n".join(lines)
    condition = " or ".join(checks)
    return f'''
tell application "Keynote"
  open POSIX file "{output}"
  delay 5
  tell document "{output.name}"
{body}
    if {condition} then error "unexpected deck counts"
    close saving no
  end tell
end tell
'''


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("spec", nargs="?", default=str(DEFAULT_SPEC),
                        help="deck spec JSON (default: the acceptance spec)")
    parser.add_argument("output", nargs="?", default=str(DEFAULT_OUTPUT),
                        help="destination .key path")
    parser.add_argument("--no-reopen", action="store_true",
                        help="generate only; skip the Keynote reopen check")
    args = parser.parse_args()

    output = Path(args.output).resolve()
    deck = deckkit.load_spec(args.spec)
    counts = [len(s.items) for s in deck.slides]
    deckkit.build(deck, str(output))

    if args.no_reopen:
        print(f"GENERATED {output}")
        return 0

    subprocess.run(["osascript", "-e", _reopen_script(output, counts)], check=True)
    print(f"PASS {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
