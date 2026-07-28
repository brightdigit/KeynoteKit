#!/usr/bin/env python3
"""
diff.py — compare two unpacked (and normalized) Keynote decks.

keynote-parser unpacks a .key into many YAML files, roughly one per
internal component (.iwa). The single most useful first signal in this
whole effort is *which files differ* — that localizes a feature to a
component before you read a single line of the delta. This tool reports
that, then emits a normalized unified diff for each changed file.

Run normalize.py --in-place on both directories first (the orchestrator
does this for you).

Usage:
    python3 diff.py DIR_A DIR_B [--out findings/experiment/]
"""
from __future__ import annotations

import argparse
import difflib
import os
import sys


def _rel_yaml_set(root: str) -> set[str]:
    out = set()
    for dirpath, _dirs, files in os.walk(root):
        for f in files:
            if f.endswith((".yaml", ".yml")):
                out.add(os.path.relpath(os.path.join(dirpath, f), root))
    return out


def _read(root: str, rel: str) -> list[str]:
    with open(os.path.join(root, rel), "r", encoding="utf-8", errors="replace") as fh:
        return fh.readlines()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("dir_a")
    ap.add_argument("dir_b")
    ap.add_argument("--out", help="write per-file diffs into this directory")
    args = ap.parse_args()

    a_files = _rel_yaml_set(args.dir_a)
    b_files = _rel_yaml_set(args.dir_b)

    only_a = sorted(a_files - b_files)
    only_b = sorted(b_files - a_files)
    common = sorted(a_files & b_files)

    changed: list[str] = []
    for rel in common:
        if _read(args.dir_a, rel) != _read(args.dir_b, rel):
            changed.append(rel)

    print("=== component-level summary ===")
    print(f"only in A ({len(only_a)}): " + (", ".join(only_a) or "-"))
    print(f"only in B ({len(only_b)}): " + (", ".join(only_b) or "-"))
    print(f"changed   ({len(changed)}): " + (", ".join(changed) or "-"))
    print()

    if args.out:
        os.makedirs(args.out, exist_ok=True)

    for rel in changed:
        a = _read(args.dir_a, rel)
        b = _read(args.dir_b, rel)
        ud = list(difflib.unified_diff(a, b, fromfile=f"A/{rel}", tofile=f"B/{rel}"))
        text = "".join(ud)
        if args.out:
            safe = rel.replace(os.sep, "__")
            with open(os.path.join(args.out, safe + ".diff"), "w", encoding="utf-8") as fh:
                fh.write(text)
        else:
            print(f"--- delta in {rel} ---")
            sys.stdout.write(text)
            print()

    if args.out and changed:
        print(f"wrote {len(changed)} diff(s) to {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
