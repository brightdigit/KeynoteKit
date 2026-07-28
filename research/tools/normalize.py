#!/usr/bin/env python3
"""
normalize.py — collapse volatile noise in keynote-parser YAML output.

Between two saves, Keynote reshuffles object identifiers, UUIDs, and
timestamps even when nothing meaningful changed. A raw text diff of two
unpacked decks is therefore swamped by noise. This tool rewrites the
volatile bits to stable placeholders so a subsequent diff surfaces only
the structural delta that corresponds to the feature you toggled.

It is intentionally text-oriented (stdlib only, no PyYAML) so it runs
anywhere and never chokes on a YAML dialect quirk. It is a v1: expect to
tune VOLATILE_KEYS and the regexes below once you have seen real output
from *your* Keynote version.

Usage:
    python3 normalize.py path/to/file.yaml            # prints normalized to stdout
    python3 normalize.py --in-place dir/               # normalize every *.yaml under dir
"""
from __future__ import annotations

import argparse
import os
import re
import sys

# --- Volatile value patterns -------------------------------------------------
# UUID-like strings (Keynote uses these liberally for object identity).
UUID_RE = re.compile(
    r"\b[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-"
    r"[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\b"
)

# Absolute timestamps (iWork stores Core Data reference dates as big floats).
# Tune the threshold if you find real durations getting clobbered.
TIMESTAMP_RE = re.compile(r"\b\d{9,}\.\d+\b")

# Numeric object identifiers. iWork assigns large integer ids (6+ digits) to
# every object and *renumbers them on every save*, so the same logical object
# gets a different id in each deck of a pair. keynote-parser dumps them as
# quoted strings, both as a component's own id and — the noisy part — as bare
# list items under objectReferences / drawablesZOrder that VOLATILE_KEYS can't
# catch (they're list items, not "key: value" lines). We canonicalize them
# first-seen -> <id:N> per file (like UUIDs) so structural identity is kept but
# the constant renumbering stops swamping the diff.
OBJ_ID_RE = re.compile(r"'(\d{6,})'")

# --- Volatile keys -----------------------------------------------------------
# Values under these YAML keys are churn, not signal. Extend after you see
# real dumps. Matches "  key: <value>" style lines.
VOLATILE_KEYS = {
    "identifier",
    "id",
    "object_id",
    "registered_id",
    "modification_date",
    "creation_date",
    "stored_uuid",
    "uuid",
    "version_uuid",
    "seed",
    "randomNumberSeed",
}

_KEYVAL_RE = re.compile(r"^(?P<indent>\s*)(?P<key>[\w.\-]+):\s*(?P<val>.+?)\s*$")


def normalize_line(line: str, id_map: dict[str, str]) -> str:
    # 1) canonicalize UUIDs consistently within the file (first-seen -> @uN)
    def _uuid_sub(m: re.Match) -> str:
        raw = m.group(0)
        if raw not in id_map:
            id_map[raw] = f"<uuid:{len(id_map)}>"
        return id_map[raw]

    line = UUID_RE.sub(_uuid_sub, line)

    # 1b) canonicalize numeric object ids consistently (first-seen -> <id:N>)
    def _id_sub(m: re.Match) -> str:
        raw = m.group(1)
        if raw not in id_map:
            id_map[raw] = f"<id:{len(id_map)}>"
        return id_map[raw]

    line = OBJ_ID_RE.sub(_id_sub, line)

    # 2) blank out absolute timestamps
    line = TIMESTAMP_RE.sub("<ts>", line)

    # 3) blank out values under known-volatile keys
    m = _KEYVAL_RE.match(line)
    if m and m.group("key") in VOLATILE_KEYS:
        return f"{m.group('indent')}{m.group('key')}: <vol>"

    return line.rstrip("\n")


def normalize_text(text: str) -> str:
    id_map: dict[str, str] = {}
    out = [normalize_line(ln, id_map) for ln in text.splitlines()]
    return "\n".join(out) + "\n"


def _iter_yaml(root: str):
    for dirpath, _dirs, files in os.walk(root):
        for f in files:
            if f.endswith((".yaml", ".yml")):
                yield os.path.join(dirpath, f)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("path", help="a .yaml file, or a directory with --in-place")
    ap.add_argument("--in-place", action="store_true",
                    help="normalize every *.yaml under the given directory")
    args = ap.parse_args()

    if args.in_place:
        if not os.path.isdir(args.path):
            print("--in-place requires a directory", file=sys.stderr)
            return 2
        n = 0
        for p in _iter_yaml(args.path):
            with open(p, "r", encoding="utf-8", errors="replace") as fh:
                norm = normalize_text(fh.read())
            with open(p, "w", encoding="utf-8") as fh:
                fh.write(norm)
            n += 1
        print(f"normalized {n} file(s) under {args.path}", file=sys.stderr)
        return 0

    with open(args.path, "r", encoding="utf-8", errors="replace") as fh:
        sys.stdout.write(normalize_text(fh.read()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
