#!/usr/bin/env python3
"""Generate and ask Keynote to reopen the authored-build acceptance deck."""
from __future__ import annotations

import subprocess
from pathlib import Path

import deckkit

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "samples/build_backend_acceptance.key"


def main() -> int:
    deck = deckkit.load_spec(str(ROOT / "examples/build_acceptance.json"))
    deckkit.build(deck, str(OUTPUT))
    script = f'''
tell application "Keynote"
  open POSIX file "{OUTPUT}"
  delay 5
  tell document "{OUTPUT.name}"
    set slideCount to count of slides
    set firstCount to count of text items of slide 1
    set secondCount to count of text items of slide 2
    if slideCount is not 2 or firstCount is not 3 or secondCount is not 1 then error "unexpected acceptance counts"
    close saving no
  end tell
end tell
'''
    subprocess.run(["osascript", "-e", script], check=True)
    print(f"PASS {OUTPUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
