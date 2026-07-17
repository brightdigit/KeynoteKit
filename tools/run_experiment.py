#!/usr/bin/env python3
"""
run_experiment.py — one command to diff a controlled pair of decks.

Pipeline:
    (optional) osascript generator  ->  A.key, B.key
    keynote-parser unpack           ->  unpacked/<exp>/A, unpacked/<exp>/B
    normalize.py --in-place         ->  collapse volatile noise
    diff.py                         ->  findings/<exp>/

Runs on macOS with Keynote + keynote-parser installed. The generate and
unpack steps shell out; use --skip-generate / --skip-unpack to re-run the
compare stage on artifacts you already have.

NOTE: confirm the keynote-parser subcommand/flags against `keynote-parser
--help` on your machine — pin the version so results are reproducible.

Examples:
    # full run, generating A/B from an AppleScript that writes two files
    python3 tools/run_experiment.py transitions \
        --generate generators/transition_matrix.applescript

    # you already have two .key files
    python3 tools/run_experiment.py transitions \
        --a samples/base.key --b samples/base_magicmove.key --skip-generate

    # re-diff already-unpacked dirs
    python3 tools/run_experiment.py transitions --skip-generate --skip-unpack
"""
from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)


def run(cmd: list[str]) -> None:
    print("+ " + " ".join(cmd), file=sys.stderr)
    subprocess.run(cmd, check=True)


def unpack(key_path: str, out_dir: str) -> None:
    if os.path.isdir(out_dir):
        shutil.rmtree(out_dir)
    os.makedirs(out_dir, exist_ok=True)
    # Adjust to match your installed keynote-parser CLI if needed.
    run(["keynote-parser", "unpack", key_path, "--output", out_dir])


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("experiment", help="short name, e.g. 'transitions'")
    ap.add_argument("--generate", help="AppleScript that writes the A/B pair")
    ap.add_argument("--a", default=None, help="path to variant A .key")
    ap.add_argument("--b", default=None, help="path to variant B .key")
    ap.add_argument("--skip-generate", action="store_true")
    ap.add_argument("--skip-unpack", action="store_true")
    args = ap.parse_args()

    exp = args.experiment
    a_key = args.a or os.path.join(ROOT, "samples", f"{exp}_A.key")
    b_key = args.b or os.path.join(ROOT, "samples", f"{exp}_B.key")
    a_dir = os.path.join(ROOT, "unpacked", exp, "A")
    b_dir = os.path.join(ROOT, "unpacked", exp, "B")
    out_dir = os.path.join(ROOT, "findings", exp)

    if not args.skip_generate:
        if not args.generate:
            print("give --generate SCRIPT or use --skip-generate with --a/--b",
                  file=sys.stderr)
            return 2
        # The generator is expected to write exactly the two sample paths.
        run(["osascript", args.generate, a_key, b_key])

    if not args.skip_unpack:
        for k in (a_key, b_key):
            if not os.path.exists(k):
                print(f"missing sample: {k}", file=sys.stderr)
                return 2
        unpack(a_key, a_dir)
        unpack(b_key, b_dir)

    norm = os.path.join(HERE, "normalize.py")
    run([sys.executable, norm, "--in-place", a_dir])
    run([sys.executable, norm, "--in-place", b_dir])

    diff = os.path.join(HERE, "diff.py")
    run([sys.executable, diff, a_dir, b_dir, "--out", out_dir])

    print(f"\ndone. read the component summary above, then inspect {out_dir}/*.diff")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
