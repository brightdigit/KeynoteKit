#!/usr/bin/env python3
"""
selftest.py — prove the normalize+diff harness works without Keynote/network.

It fabricates two 'unpacked' decks that mimic keynote-parser YAML: same
structure, differing only in (a) volatile churn (new UUIDs, new ids, new
timestamps) that should be SUPPRESSED, and (b) one real feature toggle
(a transition block) that should SURVIVE. A correct harness reports only
the real delta.
"""
from __future__ import annotations

import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))

A_SLIDE = """\
slide:
  identifier: 41201
  uuid: 11111111-2222-3333-4444-555555555555
  modification_date: 743182991.44219
  title: Alpha
  transition: none
"""

# B: identical MEANING except a real transition block; plus pure churn in
# the volatile fields (different id/uuid/timestamp) that must be ignored.
B_SLIDE = """\
slide:
  identifier: 98337
  uuid: aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee
  modification_date: 743182999.88104
  title: Alpha
  transition:
    effect: magic_move
    duration: 1.5
"""

# A component that is byte-identical in meaning but churns only volatile
# fields -> must show as UNCHANGED after normalization.
STYLE = """\
style:
  id: {id}
  uuid: {uuid}
  font: Helvetica
  size: 24
"""


def write(root: str, rel: str, text: str) -> None:
    p = os.path.join(root, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w", encoding="utf-8") as fh:
        fh.write(text)


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        a = os.path.join(tmp, "A")
        b = os.path.join(tmp, "B")
        write(a, "Index/Slide-1.yaml", A_SLIDE)
        write(b, "Index/Slide-1.yaml", B_SLIDE)
        write(a, "Index/Style-1.yaml",
              STYLE.format(id=5001, uuid="00000000-0000-0000-0000-000000000001"))
        write(b, "Index/Style-1.yaml",
              STYLE.format(id=7788, uuid="99999999-9999-9999-9999-999999999999"))

        norm = os.path.join(HERE, "normalize.py")
        subprocess.run([sys.executable, norm, "--in-place", a], check=True)
        subprocess.run([sys.executable, norm, "--in-place", b], check=True)

        diff = os.path.join(HERE, "diff.py")
        res = subprocess.run([sys.executable, diff, a, b],
                             check=True, capture_output=True, text=True)
        out = res.stdout
        print(out)

        # Assertions: Style churn suppressed, Slide transition surfaced.
        ok = True
        if "Style-1.yaml" in out.split("changed")[1].split("\n")[0]:
            print("FAIL: volatile-only Style component leaked into changes")
            ok = False
        if "Slide-1.yaml" not in out:
            print("FAIL: real transition delta was not reported")
            ok = False
        if "magic_move" not in out:
            print("FAIL: the surviving delta should mention the transition effect")
            ok = False

        print("SELFTEST PASS" if ok else "SELFTEST FAIL")
        return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
