#!/usr/bin/env python3
"""
read_builds.py — read the object builds out of one or more .key files.

Unpacks each .key with keynote-parser (to a temp dir) and prints the builds it
carries, in delivery order, via deckkit.extract_builds: kind (In/Out) / effect
(archive string) / duration / delay / direction / target drawable id / the
sparse per-build options bag (customBounce / delivery / eventTrigger / ...).

This is the Exp 9 build-effect catalog reader and a quick inspector for any
build fixture. Requires keynote-parser on PATH (run inside the mise env:
`mise exec -- python3 tools/read_builds.py fixtures/build_fx_B.key`).

Usage:
    python3 tools/read_builds.py FILE.key [FILE2.key ...] [--json]
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import deckkit  # noqa: E402


def builds_for(key_path: str) -> list[dict]:
    """Unpack a .key to a temp dir and return its builds (extract_builds)."""
    tmp = tempfile.mkdtemp(prefix="readbuilds_")
    try:
        subprocess.run(
            ["keynote-parser", "unpack", key_path, "--output", tmp],
            check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        return deckkit.extract_builds(tmp)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def _fmt_num(x) -> str:
    return "-" if x is None else (f"{x:g}" if isinstance(x, float) else str(x))


def print_human(key_path: str, builds: list[dict]) -> None:
    print(f"\n{key_path}  ({len(builds)} build(s))")
    if not builds:
        print("  (no builds)")
        return
    for i, b in enumerate(builds):
        opts = b.get("options") or {}
        opt_str = ("  " + ", ".join(f"{k}={v}" for k, v in opts.items())) if opts else ""
        print(
            f"  [{i}] kind={b.get('kind')} effect={b.get('effect')!r} "
            f"dur={_fmt_num(b.get('duration'))} delay={_fmt_num(b.get('delay'))} "
            f"direction={_fmt_num(b.get('direction'))} "
            f"drawable={b.get('drawable') or '-'}" + opt_str
        )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("keys", nargs="+", help="one or more .key files")
    ap.add_argument("--json", action="store_true", help="emit JSON")
    args = ap.parse_args()

    if not shutil.which("keynote-parser"):
        print("needs keynote-parser on PATH (use mise exec --)", file=sys.stderr)
        return 2

    result: dict[str, list[dict]] = {}
    for k in args.keys:
        if not os.path.exists(k):
            print(f"missing: {k}", file=sys.stderr)
            return 2
        result[k] = builds_for(k)

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        for k, builds in result.items():
            print_human(k, builds)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
