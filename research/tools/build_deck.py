#!/usr/bin/env python3
"""
build_deck.py — lower a Deck JSON spec to a real Keynote .key via AppleScript,
and optionally verify the built file's transitions round-trip.

Usage:
    python3 tools/build_deck.py SPEC.json OUT.key [--verify]

--verify unpacks OUT.key with keynote-parser and asserts every transition in the
spec is present with matching effect/duration/delay/auto. Requires keynote-parser
on PATH (run inside the mise env: `mise exec -- python3 tools/build_deck.py ...`).
"""
from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import deckkit  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("spec")
    ap.add_argument("out")
    ap.add_argument("--verify", action="store_true")
    args = ap.parse_args()

    deck = deckkit.load_spec(args.spec)
    out = os.path.abspath(args.out)
    print(f"building {len(deck.slides)} slide(s) -> {out}", file=sys.stderr)
    deckkit.build(deck, out)
    if not os.path.exists(out):
        print("ERROR: build did not produce the .key", file=sys.stderr)
        return 1
    print("built ok", file=sys.stderr)

    if args.verify:
        if not shutil.which("keynote-parser"):
            print("--verify needs keynote-parser on PATH (use mise exec --)",
                  file=sys.stderr)
            return 2
        tmp = tempfile.mkdtemp(prefix="deckverify_")
        try:
            subprocess.run(
                ["keynote-parser", "unpack", out, "--output", tmp],
                check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            )
            ok, msg = deckkit.verify(deck, tmp)
            print(("VERIFY PASS: " if ok else "VERIFY FAIL: ") + msg)
            return 0 if ok else 1
        finally:
            shutil.rmtree(tmp, ignore_errors=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
