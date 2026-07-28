#!/usr/bin/env python3
"""Round-trip the build, Action, and direction fixtures with the hybrid parser."""
from __future__ import annotations

import tempfile
from pathlib import Path

import archive_backend
import deckkit

ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    cases = [
        ("build_in_B.key", "build", "apple:dissolve character"),
        ("build_action_B.key", "build", "apple:action-motion-path"),
        ("direction_B.key", "direction", 11),
    ]
    with tempfile.TemporaryDirectory(prefix="keynotekit-pack-verify-") as name:
        tmp = Path(name)
        for filename, kind, expected in cases:
            unpacked = tmp / (filename + "-unpacked")
            packed = tmp / filename
            checked = tmp / (filename + "-checked")
            archive_backend._parser("unpack", ROOT / "fixtures" / filename, unpacked)
            archive_backend._parser("pack", unpacked, packed)
            archive_backend._parser("unpack", packed, checked)
            if kind == "build":
                effects = [b["effect"] for b in deckkit.extract_builds(str(checked))]
                assert expected in effects, (filename, effects)
            else:
                directions = [t["direction"] for t in deckkit.extract_transitions(str(checked))]
                assert expected in directions, (filename, directions)
            print(f"PASS {filename}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
